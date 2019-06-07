# frozen_string_literal: true

class AutoMergeProcessWorker
  include ApplicationWorker

  queue_namespace :auto_merge

  def perform(merge_request_id)
    MergeRequest.find_by_id(merge_request_id).try do |merge_request|
      AutoMergeService.new(merge_request.project, merge_request.merge_user)
                      .process(merge_request)
    end
  end
end
