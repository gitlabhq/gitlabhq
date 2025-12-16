# frozen_string_literal: true

module Import
  module Offline
    class Export < ApplicationRecord
      self.table_name = 'import_offline_exports'

      KNOWN_IMPORT_HOSTS = %w[github.com bitbucket.org gitea.com].freeze

      belongs_to :user
      belongs_to :organization, class_name: 'Organizations::Organization'

      has_one :configuration, class_name: 'Import::Offline::Configuration', foreign_key: :offline_export_id,
        inverse_of: :offline_export
      has_many :bulk_import_exports, class_name: 'BulkImports::Export', inverse_of: :offline_export

      validates :source_hostname, :status, presence: true
      validate :validate_source_hostname

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
      end

      def self.all_human_statuses
        state_machine.states.map(&:human_name)
      end

      def validate_source_hostname
        uri = Gitlab::Utils.parse_url(source_hostname)

        if KNOWN_IMPORT_HOSTS.include?(uri&.domain)
          return errors.add(:source_hostname, :invalid, message: 'must not be a known import source domain')
        end

        return if uri && uri.scheme && uri.host && uri.path.blank? && uri.query.blank?

        errors.add(:source_hostname, :invalid, message: 'must contain only scheme and host')
      end
    end
  end
end
