# frozen_string_literal: true

class MigrateExternalDiffsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :source_code_management

  def perform(merge_request_diff_id)
    diff = MergeRequestDiff.find_by_id(merge_request_diff_id)
    return unless diff

    MergeRequests::MigrateExternalDiffsService.new(diff).execute
  end
end
