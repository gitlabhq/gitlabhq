# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ScheduleDiffFilesDeletion
      BATCH_SIZE = 5
      MIGRATION = 'DeleteDiffFiles'
      DELAY_INTERVAL = 10.minutes

      def perform(diff_ids, scheduler_index)
        relation = MergeRequestDiff.where(id: diff_ids)

        job_batches = relation.pluck(:id).in_groups_of(BATCH_SIZE, false).map do |ids|
          ids.map { |id| [MIGRATION, [id]] }
        end

        job_batches.each_with_index do |jobs, inner_index|
          # This will give some space between batches of workers.
          interval = DELAY_INTERVAL * scheduler_index + inner_index.minutes

          # A single `merge_request_diff` can be associated with way too many
          # `merge_request_diff_files`. It's better to avoid scheduling big
          # batches and go with 5 at a time.
          #
          BackgroundMigrationWorker.bulk_perform_in(interval, jobs)
        end
      end
    end
  end
end
