# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class MergeRequestAssigneesMigrationProgressCheck
      include Gitlab::Utils::StrongMemoize

      RESCHEDULE_DELAY = 3.hours
      WORKER = 'PopulateMergeRequestAssigneesTable'.freeze
      DeadJobsError = Class.new(StandardError)

      def perform
        raise DeadJobsError, "Only dead background jobs in the queue for #{WORKER}" if !ongoing? && dead_jobs?

        if ongoing?
          BackgroundMigrationWorker.perform_in(RESCHEDULE_DELAY, self.class.name)
        else
          Feature.enable(:multiple_merge_request_assignees)
        end
      end

      private

      def dead_jobs?
        strong_memoize(:dead_jobs) do
          migration_klass.dead_jobs?(WORKER)
        end
      end

      def ongoing?
        strong_memoize(:ongoing) do
          migration_klass.exists?(WORKER) || migration_klass.retrying_jobs?(WORKER)
        end
      end

      def migration_klass
        Gitlab::BackgroundMigration
      end
    end
    # rubocop: enable Style/Documentation
  end
end
