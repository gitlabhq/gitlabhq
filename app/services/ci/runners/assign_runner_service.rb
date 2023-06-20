# frozen_string_literal: true

module Ci
  module Runners
    class AssignRunnerService
      # @param [Ci::Runner] runner: the runner to assign to a project
      # @param [Project] project: the new project to assign the runner to
      # @param [User] user: the user performing the operation
      def initialize(runner, project, user)
        @runner = runner
        @project = project
        @user = user
      end

      def execute
        unless @user.present? && @user.can?(:assign_runner, @runner)
          return ServiceResponse.error(message: 'user not allowed to assign runner', http_status: :forbidden)
        end

        unless @user.can?(:register_project_runners, @project)
          return ServiceResponse.error(message: 'user not allowed to add runners to project', http_status: :forbidden)
        end

        if @runner.assign_to(@project, @user)
          ServiceResponse.success
        else
          ServiceResponse.error(message: 'failed to assign runner')
        end
      end

      private

      attr_reader :runner, :project, :user
    end
  end
end

Ci::Runners::AssignRunnerService.prepend_mod
