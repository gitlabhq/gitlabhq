# frozen_string_literal: true

module Environments
  class AutoRecoverService
    include ::Gitlab::ExclusiveLeaseHelpers
    include ::Gitlab::LoopHelpers

    BATCH_SIZE = 100
    LOOP_TIMEOUT = 45.minutes
    LOOP_LIMIT = 1000
    EXCLUSIVE_LOCK_KEY = 'environments:auto_recover:lock'
    LOCK_TIMEOUT = 50.minutes

    ##
    # Recover environments that are stuck stopping on a GitLab instance
    #
    # This auto stop process cannot run for more than 45 minutes. This is for
    # preventing multiple `AutoStopCronWorker` CRON jobs run concurrently,
    # which is scheduled at every hour.
    def execute
      in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
        loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
          recover_in_batch
        end
      end
    end

    private

    def recover_in_batch
      environments = Environment.preload_project.select(:id, :project_id).long_stopping.limit(BATCH_SIZE)

      return false if environments.empty?

      Environments::AutoRecoverWorker.bulk_perform_async_with_contexts(
        environments,
        arguments_proc: ->(environment) { environment.id },
        context_proc: ->(environment) { { project: environment.project } }
      )

      true
    end
  end
end
