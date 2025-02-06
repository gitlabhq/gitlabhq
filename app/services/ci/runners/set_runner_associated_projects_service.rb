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
        @project_ids = project_ids || []
      end

      def execute
        unless current_user&.can?(:assign_runner, runner)
          return ServiceResponse.error(message: _('user not allowed to assign runner'),
            reason: :not_authorized_to_assign_runner)
        end

        set_associated_projects
      end

      private

      def set_associated_projects
        new_project_ids = [runner.owner&.id].compact + project_ids

        associate_response = ServiceResponse.success
        dissociate_response = ServiceResponse.success
        runner.transaction do
          current_project_ids = runner.project_ids

          associate_response = associate_new_projects(new_project_ids, current_project_ids)
          raise ActiveRecord::Rollback, associate_response.errors if associate_response.error?

          dissociate_response = disassociate_old_projects(new_project_ids, current_project_ids)
          raise ActiveRecord::Rollback, dissociate_response.errors if dissociate_response.error?
        end

        return associate_response if associate_response.error?
        return dissociate_response if dissociate_response.error?

        ServiceResponse.success(payload: {
          added_to_projects: associate_response.payload[:added_to_projects],
          deleted_from_projects: dissociate_response.payload[:deleted_from_projects]
        })
      end

      def associate_new_projects(new_project_ids, current_project_ids)
        missing_projects =
          Project.id_in(new_project_ids - current_project_ids)
           .sort_by { |project| new_project_ids.index(project.id) }

        error_responses = missing_projects.map do |project|
          Ci::Runners::AssignRunnerService.new(runner, project, current_user, quiet: true)
        end.map(&:execute).select(&:error?)

        if error_responses.any?
          return error_responses.sole if error_responses.one?

          return ServiceResponse.error(
            message: error_responses.map(&:message).uniq,
            reason: :multiple_errors
          )
        end

        ServiceResponse.success(payload: { added_to_projects: missing_projects })
      end

      def disassociate_old_projects(new_project_ids, current_project_ids)
        project_ids_to_be_deleted = current_project_ids - new_project_ids

        if project_ids_to_be_deleted.any?
          all_destroyed =
            Ci::RunnerProject
              .destroy_by(project_id: project_ids_to_be_deleted)
              .all?(&:destroyed?)

          unless all_destroyed
            return ServiceResponse.error(
              message: _('failed to destroy runner project'),
              reason: :failed_runner_project_destroy)
          end
        end

        ServiceResponse.success(payload: { deleted_from_projects: ::Project.id_in(project_ids_to_be_deleted) })
      end

      attr_reader :runner, :current_user, :project_ids
    end
  end
end

Ci::Runners::SetRunnerAssociatedProjectsService.prepend_mod
