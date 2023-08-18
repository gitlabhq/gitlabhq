# frozen_string_literal: true

module BatchedGitRefUpdates
  class CleanupSchedulerService
    include Gitlab::ExclusiveLeaseHelpers
    MAX_PROJECTS = 10_000
    BATCH_SIZE = 100
    LOCK_TIMEOUT = 10.minutes

    def execute
      total_projects = 0

      in_lock(self.class.name, retries: 0, ttl: LOCK_TIMEOUT) do
        Deletion.status_pending.distinct_each_batch(column: :project_id, of: BATCH_SIZE) do |deletions|
          ProjectCleanupWorker.bulk_perform_async_with_contexts(
            deletions,
            arguments_proc: ->(deletion) { deletion.project_id },
            context_proc: ->(_) { {} } # No project context because loading the project is wasteful
          )

          total_projects += deletions.count
          break if total_projects >= MAX_PROJECTS
        end
      end

      { total_projects: total_projects }
    end
  end
end
