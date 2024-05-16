# frozen_string_literal: true

module Ci
  module ResourceGroups
    # This worker is a copy of Ci::ResourceGroups::AssignResourceFromResourceGroupWorker
    #   with a different deduplication strategy.
    # The old AssignResourceFromResourceGroupWorker has a deduplication strategy of `until_executed`,
    #   whereas this AssignResourceFromResourceGroupWorkerV2 has a strategy of `until_executing`.
    # We are also using the same data_consistency (always) as the old AssignResourceFromResourceGroupWorker
    #   since this needs to process the latest/real-time data.
    class AssignResourceFromResourceGroupWorkerV2
      include ApplicationWorker

      data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency -- see comment above

      sidekiq_options retry: 3
      include PipelineQueue

      queue_namespace :pipeline_processing
      feature_category :continuous_delivery

      # This worker is idempotent that it produces the same result
      # as long as the same resource group id is passed as an argument.
      # We often run into a race condition with an `until_executed` strategy,
      # so we are using an `until_executing` strategy here.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/436988 for details.
      idempotent!
      deduplicate :until_executing, if_deduplicated: :reschedule_once, including_scheduled: true

      def perform(resource_group_id)
        ::Ci::ResourceGroup.find_by_id(resource_group_id).try do |resource_group|
          Ci::ResourceGroups::AssignResourceFromResourceGroupService.new(resource_group.project, nil)
            .execute(resource_group)
        end
      end
    end
  end
end
