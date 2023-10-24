# frozen_string_literal: true

module Projects
  module GroupLinks
    class DestroyService < BaseService
      def execute(group_link, skip_authorization: false)
        unless valid_to_destroy?(group_link, skip_authorization)
          return ServiceResponse.error(message: 'Not found', reason: :not_found)
        end

        if group_link.project.private?
          TodosDestroyer::ProjectPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
        else
          TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, nil, project.id)
        end

        link = group_link.destroy

        refresh_project_authorizations_asynchronously(link.project)

        # Until we compare the inconsistency rates of the new specialized worker and
        # the old approach, we still run AuthorizedProjectsWorker
        # but with some delay and lower urgency as a safety net.
        link.group.refresh_members_authorized_projects(
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )

        ServiceResponse.success(payload: { link: link })
      end

      private

      def valid_to_destroy?(group_link, skip_authorization)
        return false unless group_link
        return true if skip_authorization

        current_user.can?(:admin_project_group_link, group_link)
      end

      def refresh_project_authorizations_asynchronously(project)
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)
      end
    end
  end
end

Projects::GroupLinks::DestroyService.prepend_mod_with('Projects::GroupLinks::DestroyService')
