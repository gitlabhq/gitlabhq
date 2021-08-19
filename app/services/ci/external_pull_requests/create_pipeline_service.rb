# frozen_string_literal: true

# This service is responsible for creating a pipeline for a given
# ExternalPullRequest coming from other providers such as GitHub.

module Ci
  module ExternalPullRequests
    class CreatePipelineService < BaseService
      def execute(pull_request)
        return pull_request_not_open_error unless pull_request.open?
        return pull_request_branch_error unless pull_request.actual_branch_head?

        create_pipeline_for(pull_request)
      end

      private

      def create_pipeline_for(pull_request)
        Ci::CreatePipelineService.new(project, current_user, create_params(pull_request))
          .execute(:external_pull_request_event, external_pull_request: pull_request)
      end

      def create_params(pull_request)
        {
          ref: pull_request.source_ref,
          source_sha: pull_request.source_sha,
          target_sha: pull_request.target_sha
        }
      end

      def pull_request_not_open_error
        ServiceResponse.error(message: 'The pull request is not opened', payload: nil)
      end

      def pull_request_branch_error
        ServiceResponse.error(message: 'The source sha is not the head of the source branch', payload: nil)
      end
    end
  end
end
