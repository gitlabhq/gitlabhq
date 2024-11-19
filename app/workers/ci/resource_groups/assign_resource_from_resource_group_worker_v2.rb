# frozen_string_literal: true

module Ci
  module ResourceGroups
    # This worker is a copy of Ci::ResourceGroups::AssignResourceFromResourceGroupWorker
    #   with a different deduplication strategy.
    # The old AssignResourceFromResourceGroupWorker has a deduplication strategy of `until_executed`,
    #   whereas this AssignResourceFromResourceGroupWorkerV2 has a strategy of `until_executing`.
    # We are also using the same data_consistency (always) as the old AssignResourceFromResourceGroupWorker
    #   since this needs to process the latest/real-time data.
    #
    # 2024-10-17 Update:
    #   This worker is no longer needed and is not being called anywhere in the code base.
    #   This will no-op when `perform` is called.
    #   See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168483
    #
    # TODO: this worker should be completely removed in the future.
    #   Removal issue: https://gitlab.com/gitlab-org/gitlab/-/issues/499658
    class AssignResourceFromResourceGroupWorkerV2
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include PipelineQueue

      queue_namespace :pipeline_processing
      feature_category :continuous_delivery

      idempotent!
      deduplicate :until_executing, if_deduplicated: :reschedule_once, including_scheduled: true

      def perform(resource_group_id); end
    end
  end
end
