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
        return false unless @user.present? && @user.can?(:assign_runner, @runner)

        @runner_project.destroy
      end

      private

      attr_reader :runner, :project, :user
    end
  end
end

Ci::Runners::UnassignRunnerService.prepend_mod
