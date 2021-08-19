# frozen_string_literal: true

class AutoMergeProcessWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  queue_namespace :auto_merge
  feature_category :continuous_delivery
  worker_resource_boundary :cpu

  def perform(merge_request_id)
    MergeRequest.find_by_id(merge_request_id).try do |merge_request|
      AutoMergeService.new(merge_request.project, merge_request.merge_user)
                      .process(merge_request)
    end
  end
end
