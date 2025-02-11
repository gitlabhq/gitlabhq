# frozen_string_literal: true

module Ci
  module Runners
    class UnassignRunnerService
      # @param [Ci::RunnerProject] runner_project the runner/project association to destroy
      # @param [User] user the user performing the operation
      def initialize(runner_project, user)
        @runner_project = runner_project
        @runner = runner_project.runner
        @project = runner_project.project
        @user = user
      end

      def execute
        response = authorize
        return response if response.error?

        if @runner_project.destroy
          ServiceResponse.success
        else
          ServiceResponse.error(message: 'Failed to destroy runner project')
        end
      end

      private

      attr_reader :runner, :project, :user

      def authorize
        unless user.present? && user.can?(:assign_runner, runner)
          return ServiceResponse.error(message: 'User not allowed to assign runner')
        end

        unless user.can?(:admin_project_runners, project)
          return ServiceResponse.error(message: "User not allowed to manage project's runners")
        end

        if project == runner.owner
          return ServiceResponse.error(
            message: 'You cannot unassign a runner from the owner project. Delete the runner instead'
          )
        end

        ServiceResponse.success
      end
    end
  end
end

Ci::Runners::UnassignRunnerService.prepend_mod
