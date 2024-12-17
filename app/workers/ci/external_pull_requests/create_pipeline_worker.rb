# frozen_string_literal: true

module Ci
  module ExternalPullRequests
    class CreatePipelineWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :sticky
      queue_namespace :pipeline_creation
      feature_category :pipeline_composition
      urgency :high
      worker_resource_boundary :cpu

      def perform(project_id, user_id, external_pull_request_id)
        user = User.find_by_id(user_id)
        return unless user

        project = Project.find_by_id(project_id)
        return unless project

        external_pull_request = project.external_pull_requests.find_by_id(external_pull_request_id)
        return unless external_pull_request

        ::Ci::CreatePipelineService
          .new(project, user, execute_params(external_pull_request))
          .execute(:external_pull_request_event, external_pull_request: external_pull_request)
      end

      private

      def execute_params(pull_request)
        {
          ref: pull_request.source_ref,
          source_sha: pull_request.source_sha,
          target_sha: pull_request.target_sha
        }
      end
    end
  end
end
