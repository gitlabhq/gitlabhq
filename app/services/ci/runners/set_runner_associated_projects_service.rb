# frozen_string_literal: true

module Ci
  module Runners
    class SetRunnerAssociatedProjectsService
      # @param [Ci::Runner] runner: the project runner to assign/unassign projects from
      # @param [User] current_user: the user performing the operation
      # @param [Array<Integer>] project_ids: the IDs of the associated projects to assign the runner to
      def initialize(runner:, current_user:, project_ids:)
        @runner = runner
        @current_user = current_user
        @project_ids = project_ids
      end

      def execute
        unless current_user&.can?(:assign_runner, runner)
          return ServiceResponse.error(message: _('user not allowed to assign runner'),
            reason: :not_authorized_to_assign_runner)
        end

        return ServiceResponse.success if project_ids.nil?

        set_associated_projects
      end

      private

      def set_associated_projects
        new_project_ids = [runner.owner_project.id] + project_ids

        response = ServiceResponse.success
        runner.transaction do
          # rubocop:disable CodeReuse/ActiveRecord
          current_project_ids = runner.projects.ids
          # rubocop:enable CodeReuse/ActiveRecord

          response = associate_new_projects(new_project_ids, current_project_ids)
          response = disassociate_old_projects(new_project_ids, current_project_ids) if response.success?
          raise ActiveRecord::Rollback, response.errors unless response.success?
        end

        response
      end

      def associate_new_projects(new_project_ids, current_project_ids)
        missing_projects = Project.id_in(new_project_ids - current_project_ids)

        error_responses = missing_projects.map do |project|
          Ci::Runners::AssignRunnerService.new(runner, project, current_user, quiet: true)
        end.map(&:execute).select(&:error?)

        if error_responses.any?
          return error_responses.first if error_responses.count == 1

          return ServiceResponse.error(
            message: error_responses.map(&:message).uniq,
            reason: :multiple_errors
          )
        end

        ServiceResponse.success
      end

      def disassociate_old_projects(new_project_ids, current_project_ids)
        projects_to_be_deleted = current_project_ids - new_project_ids
        return ServiceResponse.success if projects_to_be_deleted.empty?

        all_destroyed =
          Ci::RunnerProject
            .destroy_by(project_id: projects_to_be_deleted)
            .all?(&:destroyed?)
        return ServiceResponse.success if all_destroyed

        ServiceResponse.error(message: _('failed to destroy runner project'), reason: :failed_runner_project_destroy)
      end

      attr_reader :runner, :current_user, :project_ids
    end
  end
end

Ci::Runners::SetRunnerAssociatedProjectsService.prepend_mod
