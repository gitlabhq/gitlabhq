# frozen_string_literal: true

# This service is responsible for creating a pipeline for a given
# ExternalPullRequest coming from other providers such as GitHub.

module Ci
  module ExternalPullRequests
    class CreatePipelineService < BaseService
      def execute(pull_request)
        return pull_request_not_open_error unless pull_request.open?
        return pull_request_branch_error unless pull_request.actual_branch_head?

        Ci::ExternalPullRequests::CreatePipelineWorker.perform_async(
          project.id, current_user.id, pull_request.id
        )
      end

      private

      def pull_request_not_open_error
        ServiceResponse.error(message: 'The pull request is not opened', payload: nil)
      end

      def pull_request_branch_error
        ServiceResponse.error(message: 'The source sha is not the head of the source branch', payload: nil)
      end
    end
  end
end
