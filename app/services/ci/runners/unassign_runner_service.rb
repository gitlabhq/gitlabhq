# frozen_string_literal: true

module Ci
  module Runners
    class UnassignRunnerService
      # @param [Ci::RunnerProject] runner_project the runner/project association to destroy
      # @param [User] user the user performing the operation
      def initialize(runner_project, user)
        @runner = runner_project.runner
        @runner_project = runner_project
        @user = user
      end

      def execute
        return false unless @user.present? && @user.can?(:assign_runner, @runner)

        @runner_project.destroy
      end
    end
  end
end
