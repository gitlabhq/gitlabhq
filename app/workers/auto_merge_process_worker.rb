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

  PROJECT_MR_LIMIT = 30

  def perform(params = {})
    # Passing an integer id to AutoMergeProcessWorker is deprecated.
    # This is here to support existing implementations while we transition
    # to a params hash. https://gitlab.com/gitlab-org/gitlab/-/issues/497247
    params = { 'merge_request_id' => params } unless params.is_a?(Hash)

    merge_requests = all_merge_requests(params)
    return if merge_requests.empty?

    # All merge requests in a single invocation share the same source
    # project (see `Ci::Pipeline#all_merge_requests`), so the flag is
    # checked once with that project as the actor.
    if Feature.enabled?(:auto_merge_diagnostic_logging, merge_requests.first.project)
      log_diagnostic(params, merge_requests)
    end

    merge_requests.each do |merge_request|
      AutoMergeService.new(merge_request.project, merge_request.merge_user).process(merge_request)
    end
  end

  private

  # Diagnostic logging for https://gitlab.com/gitlab-org/gitlab/-/issues/596177.
  # Records which trigger invoked the worker so a stuck auto-merge can be
  # correlated with the CI mergeability diagnostic. Behind the
  # `auto_merge_diagnostic_logging` ops flag, enabled per-project.
  def log_diagnostic(params, merge_requests)
    Gitlab::AppJsonLogger.info(
      message: 'auto_merge_worker_invoked',
      trigger_source: params.keys.sort.join(','),
      triggering_pipeline_ids: Array.wrap(params['pipeline_id']),
      merge_request_ids: merge_requests.map(&:id)
    )
  end

  def all_merge_requests(params)
    merge_requests = params['merge_request_id'].try do |mr_id|
      MergeRequest.id_in(mr_id)
    end

    pipeline_merge_requests = params['pipeline_id'].try do |pipe_id|
      Ci::Pipeline.id_in(pipe_id).flat_map do |pipeline|
        pipeline.all_merge_requests.with_auto_merge_enabled
      end
    end

    (merge_requests.to_a + pipeline_merge_requests.to_a).uniq
  end
end

AutoMergeProcessWorker.prepend_mod
