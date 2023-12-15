# frozen_string_literal: true

module Projects
  module GroupLinks
    class DestroyService < BaseService
      def execute(group_link, skip_authorization: false)
        return not_found! unless group_link

        unless skip_authorization
          return not_found! unless allowed_to_manage_destroy?(group_link)

          unless allowed_to_destroy_link?(group_link)
            return ServiceResponse.error(message: 'Forbidden', reason: :forbidden)
          end
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

      def not_found!
        ServiceResponse.error(message: 'Not found', reason: :not_found)
      end

      def allowed_to_manage_destroy?(group_link)
        current_user.can?(:manage_destroy, group_link)
      end

      def allowed_to_destroy_link?(group_link)
        current_user.can?(:destroy_project_group_link, group_link)
      end

      def refresh_project_authorizations_asynchronously(project)
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)
      end
    end
  end
end

Projects::GroupLinks::DestroyService.prepend_mod_with('Projects::GroupLinks::DestroyService')
