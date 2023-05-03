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
          return ServiceResponse.error(message: 'user not allowed to assign runner', http_status: :forbidden)
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

        unless missing_projects.all? { |project| current_user.can?(:register_project_runners, project) }
          return ServiceResponse.error(message: 'user is not authorized to add runners to project')
        end

        unless missing_projects.all? { |project| runner.assign_to(project, current_user) }
          return ServiceResponse.error(message: 'failed to assign projects to runner')
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

        ServiceResponse.error(message: 'failed to destroy runner project')
      end

      attr_reader :runner, :current_user, :project_ids
    end
  end
end

Ci::Runners::SetRunnerAssociatedProjectsService.prepend_mod
