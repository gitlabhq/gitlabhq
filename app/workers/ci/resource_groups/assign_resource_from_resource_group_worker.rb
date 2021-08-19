# frozen_string_literal: true

module Ci
  module ResourceGroups
    # This worker is to assign a resource to a pipeline job from a resource group
    # and enqueue the job to be executed by a runner.
    # See https://docs.gitlab.com/ee/ci/yaml/#resource_group for more information.
    class AssignResourceFromResourceGroupWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include PipelineQueue

      queue_namespace :pipeline_processing
      feature_category :continuous_delivery

      # This worker is idempotent that it produces the same result
      # as long as the same resource group id is passed as an argument.
      # Therefore, we can deduplicate the sidekiq jobs until the on-going
      # assignment process has been finished.
      idempotent!
      deduplicate :until_executed

      def perform(resource_group_id)
        ::Ci::ResourceGroup.find_by_id(resource_group_id).try do |resource_group|
          Ci::ResourceGroups::AssignResourceFromResourceGroupService.new(resource_group.project, nil)
            .execute(resource_group)
        end
      end
    end
  end
end
