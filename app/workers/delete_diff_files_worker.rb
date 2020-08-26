# frozen_string_literal: true

class DeleteDiffFilesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :source_code_management

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(merge_request_diff_id)
    merge_request_diff = MergeRequestDiff.find(merge_request_diff_id)

    return if merge_request_diff.without_files?

    MergeRequestDiff.transaction do
      MergeRequestDiffFile
        .where(merge_request_diff_id: merge_request_diff.id)
        .delete_all

      merge_request_diff.clean!
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
