# frozen_string_literal: true

module Ci
  module Runners
    # Service used to assign a runner to a project.
    # This class can be reused by SetRunnerAssociatedProjectsService in the context of a bulk assignment.
    class AssignRunnerService
      # @param [Ci::Runner] runner: the runner to assign to a project
      # @param [Project] project: the new project to assign the runner to
      # @param [User] user: the user performing the operation
      # @param [Boolean] quiet: true if service should avoid side effects, such as logging
      #   (e.g. when used by another service)
      def initialize(runner, project, user, quiet: false)
        @runner = runner
        @project = project
        @user = user
        @quiet = quiet
      end

      def execute
        response = validate
        return response if response.error?

        if @runner.assign_to(@project, @user)
          ServiceResponse.success
        else
          ServiceResponse.error(
            message: @runner.errors.full_messages_for(:assign_to).presence || _('failed to assign runner to project'),
            reason: :runner_error)
        end
      end

      private

      attr_reader :runner, :project, :user, :quiet

      def validate
        unless @user.present? && @user.can?(:assign_runner, @runner)
          return ServiceResponse.error(message: _('user not allowed to assign runner'),
            reason: :not_authorized_to_assign_runner)
        end

        unless @user.can?(:create_runner, @project)
          return ServiceResponse.error(message: _('user is not authorized to add runners to project'),
            reason: :not_authorized_to_add_runner_in_project)
        end

        if runner.owner && project.organization_id != runner.owner.organization_id
          return ServiceResponse.error(message: _('runner can only be assigned to projects in the same organization'),
            reason: :project_not_in_same_organization)
        end

        ServiceResponse.success
      end
    end
  end
end

Ci::Runners::AssignRunnerService.prepend_mod
