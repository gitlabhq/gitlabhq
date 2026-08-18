# frozen_string_literal: true

module Import
  module Offline
    class Export < ApplicationRecord
      include AfterCommitQueue
      include Gitlab::InternalEventsTracking

      self.table_name = 'import_offline_exports'

      ignore_column :source_hostname, remove_with: '19.4', remove_after: '2026-08-21'

      PURGE_CONFIGURATION_DELAY = 24.hours

      belongs_to :user
      belongs_to :organization, class_name: 'Organizations::Organization'

      has_one :configuration, class_name: 'Import::Offline::Configuration', foreign_key: :offline_export_id,
        inverse_of: :offline_export
      has_many :bulk_import_exports, class_name: 'BulkImports::Export', inverse_of: :offline_export

      validates :status, presence: true

      scope :including_configuration, -> { includes(:configuration) }
      scope :order_by_created_at, ->(direction) { order(created_at: direction) }

      state_machine :status, initial: :created do
        state :created, value: 0
        state :started, value: 1
        state :finished, value: 2
        state :failed, value: -1

        event :start do
          transition created: :started
        end

        event :finish do
          transition started: :finished
        end

        event :fail_op do
          transition any => :failed
        end

        after_transition any => [:finished, :failed] do |export|
          export.run_after_commit { export.schedule_configuration_purge }
        end

        after_transition any => :finished do |export|
          export.run_after_commit do
            Notify.offline_export_complete(export.user_id, export.id).deliver_later

            export.track_internal_event(
              'complete_offline_transfer_export',
              user: export.user,
              additional_properties: { label: export.has_failures? ? 'with_failures' : 'without_failures' }
            )
          end
        end

        after_transition any => :failed do |export|
          export.run_after_commit do
            Notify.offline_export_failed(export.user_id, export.id).deliver_later

            export.track_internal_event('fail_offline_transfer_export', user: export.user)
          end
        end
      end

      def self.all_human_statuses
        state_machine.states.map(&:human_name)
      end

      def source_hostname
        configuration&.source_hostname
      end

      def completed?
        finished? || failed?
      end

      def schedule_configuration_purge
        return unless configuration

        ::Import::Offline::ConfigurationPurgeWorker.perform_in(PURGE_CONFIGURATION_DELAY, configuration.id)
      end

      def update_has_failures!
        return if has_failures?

        update!(has_failures: true)
      end

      def included_group_routes
        included_routes_for_portable_type(Group)
      end

      def included_project_routes
        included_routes_for_portable_type(Project)
      end

      private

      # Only finished relation exports are considered included in the export
      def included_routes_for_portable_type(portable_class)
        finished_relation_exports = bulk_import_exports.for_status(::BulkImports::Export::FINISHED)

        portable_ids_query = if portable_class == Group
                               finished_relation_exports.group_exports.select(:group_id)
                             else
                               finished_relation_exports.project_exports.select(:project_id)
                             end

        Route.for_routable_type(portable_class.base_class.name).where(source_id: portable_ids_query)
      end
    end
  end
end
