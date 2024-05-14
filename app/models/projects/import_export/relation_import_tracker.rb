# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationImportTracker < ApplicationRecord
      belongs_to :project

      validates :project, presence: true
      validates :status, presence: true
      validates :relation, presence: true
      validate :cannot_be_created_for_importing_project, on: :create

      enum :relation, { issues: 0, merge_requests: 1, ci_pipelines: 2, milestones: 3 }

      state_machine :status, initial: :created do
        state :created, value: 0
        state :started, value: 1
        state :finished, value: 2
        state :failed, value: 3

        event :start do
          transition created: :started
        end

        event :finish do
          transition started: :finished
        end

        event :fail_op do
          transition %i[created started] => :failed
        end
      end

      def stale?
        return false if finished? || failed?

        created_at.before?(24.hours.ago)
      end

      private

      def cannot_be_created_for_importing_project
        return if project.nil?
        return unless project.import_state && !project.import_state.completed?

        errors.add(:base, _('Relation import tracker cannot be created for project with ongoing import'))
      end
    end
  end
end
