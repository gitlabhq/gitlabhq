# frozen_string_literal: true

module Projects
  module GroupLinks
    class DestroyService < BaseService
      def execute(group_link)
        return false unless group_link

        if group_link.project.private?
          TodosDestroyer::ProjectPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
        else
          TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, nil, project.id)
        end

        group_link.destroy.tap do |link|
          if Feature.enabled?(:use_specialized_worker_for_project_auth_recalculation)
            refresh_project_authorizations_asynchronously(link.project)

            # Until we compare the inconsistency rates of the new specialized worker and
            # the old approach, we still run AuthorizedProjectsWorker
            # but with some delay and lower urgency as a safety net.
            link.group.refresh_members_authorized_projects(
              blocking: false,
              priority: UserProjectAccessChangedService::LOW_PRIORITY
            )
          else
            link.group.refresh_members_authorized_projects
          end
        end
      end

      private

      def refresh_project_authorizations_asynchronously(project)
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)
      end
    end
  end
end

Projects::GroupLinks::DestroyService.prepend_mod_with('Projects::GroupLinks::DestroyService')
