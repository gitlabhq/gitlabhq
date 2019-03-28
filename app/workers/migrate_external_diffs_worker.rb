# frozen_string_literal: false

class MigrateExternalDiffsWorker
  include ApplicationWorker

  def perform(merge_request_diff_id)
    diff = MergeRequestDiff.find_by_id(merge_request_diff_id)
    return unless diff

    MergeRequests::MigrateExternalDiffsService.new(diff).execute
  end
end
