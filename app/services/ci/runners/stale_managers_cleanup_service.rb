# frozen_string_literal: true

module Ci
  module Runners
    class StaleManagersCleanupService
      MAX_DELETIONS = 1000
      SUB_BATCH_LIMIT = 100

      def execute
        ServiceResponse.success(payload: delete_stale_runner_managers)
      end

      private

      def delete_stale_runner_managers
        batch_counts = []
        total_deleted_count = 0
        loop do
          sub_batch_limit = [SUB_BATCH_LIMIT, MAX_DELETIONS].min

          # delete_all discards part of the `stale` scope query, so we explicitly wrap it with a SELECT as a workaround
          deleted_count = Ci::RunnerManager.id_in(Ci::RunnerManager.stale.limit(sub_batch_limit)).delete_all
          batch_counts << deleted_count
          total_deleted_count += deleted_count

          break if deleted_count == 0 || total_deleted_count >= MAX_DELETIONS
        end

        {
          total_deleted: total_deleted_count,
          batch_counts: batch_counts
        }
      end
    end
  end
end
