# frozen_string_literal: true

module Ci
  module Workloads
    class WorkloadBranchService
      def initialize(project:, source_branch:, current_user:)
        @project = project
        @current_user = current_user
        @source_branch = source_branch
      end

      def execute
        unless @current_user.can?(:push_code, @project)
          return ServiceResponse.error(message: 'You are not allowed to create branches in this project')
        end

        branch_name = "workloads/#{SecureRandom.hex[0..10]}"
        if @project.repository.branch_exists?(branch_name)
          return ServiceResponse.error(message: 'Branch already exists')
        end

        ref = @project.repository.branch_exists?(@source_branch) ? @source_branch : default_branch

        repo_branch = @project.repository.add_branch(@current_user, branch_name, ref, skip_ci: true)
        return ServiceResponse.error(message: 'Error in git branch creation') unless repo_branch

        ServiceResponse.success(payload: { branch_name: branch_name })
      rescue Gitlab::Git::CommandError => e
        Gitlab::ErrorTracking.track_exception(e)
        ServiceResponse.error(message: 'Failed to create branch')
      end

      private

      def default_branch
        @project.default_branch_or_main
      end
    end
  end
end
