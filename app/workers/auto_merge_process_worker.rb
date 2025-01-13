# frozen_string_literal: true

class AutoMergeProcessWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :sticky
  sidekiq_options retry: 3

  # Avoid _simultaneous execution_ of this job for the same MR,
  # but reschedule the second job just in case the first fails.
  deduplicate :until_executed, if_deduplicated: :reschedule_once

  queue_namespace :auto_merge
  feature_category :continuous_delivery
  worker_resource_boundary :cpu

  def perform(params = {})
    # Passing an integer id to AutoMergeProcessWorker is deprecated.
    # This is here to support existing implementations while we transition
    # to a params hash. https://gitlab.com/gitlab-org/gitlab/-/issues/497247
    params = { 'merge_request_id' => params } unless params.is_a?(Hash)

    merge_requests = params['merge_request_id'].try do |mr_id|
      MergeRequest.id_in(mr_id)
    end

    pipeline_merge_requests = params['pipeline_id'].try do |pipe_id|
      Ci::Pipeline.id_in(pipe_id).flat_map do |pipeline|
        pipeline.all_merge_requests.with_auto_merge_enabled
      end
    end

    all_merge_requests = merge_requests.to_a + pipeline_merge_requests.to_a

    all_merge_requests.each do |merge_request|
      AutoMergeService.new(merge_request.project, merge_request.merge_user).process(merge_request)
    end
  end
end
