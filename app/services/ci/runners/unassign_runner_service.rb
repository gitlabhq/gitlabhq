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
        return ServiceResponse.success if Ability.allowed?(user, :unassign_runner, @runner_project)

        unless Ability.allowed?(user, :admin_runners, project)
          return ServiceResponse.error(message: "User not allowed to manage project's runners")
        end

        if project == runner.owner
          return ServiceResponse.error(
            message: 'You cannot unassign a runner from the owner project. Delete the runner instead'
          )
        end

        return ServiceResponse.error(message: 'Runner is locked') if runner.locked && !user&.can_admin_all_resources?

        ServiceResponse.error(message: 'User not allowed to unassign runner')
      end
    end
  end
end

Ci::Runners::UnassignRunnerService.prepend_mod
