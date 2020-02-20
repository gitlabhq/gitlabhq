# frozen_string_literal: true

module MergeRequests
  class DeleteNonLatestDiffsService
    BATCH_SIZE = 10

    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute
      diffs = @merge_request.non_latest_diffs.with_files

      diffs.each_batch(of: BATCH_SIZE) do |relation, index|
        ids = relation.pluck_primary_key.map { |id| [id] }
        DeleteDiffFilesWorker.bulk_perform_in(index * 5.minutes, ids) # rubocop:disable Scalability/BulkPerformWithContext
      end
    end
  end
end
