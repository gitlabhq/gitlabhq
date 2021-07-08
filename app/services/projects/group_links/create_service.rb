# frozen_string_literal: true

module Projects
  module GroupLinks
    class CreateService < BaseService
      def execute(group)
        return error('Not Found', 404) unless group && can?(current_user, :read_namespace, group)

        link = project.project_group_links.new(
          group: group,
          group_access: params[:link_group_access],
          expires_at: params[:expires_at]
        )

        if link.save
          setup_authorizations(group)
          success(link: link)
        else
          error(link.errors.full_messages.to_sentence, 409)
        end
      end

      private

      def setup_authorizations(group)
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)

        # AuthorizedProjectsWorker uses an exclusive lease per user but
        # specialized workers might have synchronization issues. Until we
        # compare the inconsistency rates of both approaches, we still run
        # AuthorizedProjectsWorker but with some delay and lower urgency as a
        # safety net.
        group.refresh_members_authorized_projects(
          blocking: false,
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )
      end
    end
  end
end

Projects::GroupLinks::CreateService.prepend_mod_with('Projects::GroupLinks::CreateService')
