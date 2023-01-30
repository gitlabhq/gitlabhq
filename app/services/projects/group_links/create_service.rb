# frozen_string_literal: true

module Projects
  module GroupLinks
    class CreateService < BaseService
      include GroupLinkable

      def initialize(project, shared_with_group, user, params)
        @shared_with_group = shared_with_group

        super(project, user, params)
      end

      private

      delegate :root_ancestor, to: :project

      def valid_to_create?
        can?(current_user, :read_namespace, shared_with_group) && sharing_allowed?
      end

      def build_link
        @link = project.project_group_links.new(
          group: shared_with_group,
          group_access: params[:link_group_access],
          expires_at: params[:expires_at]
        )
      end

      def setup_authorizations
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)

        # AuthorizedProjectsWorker uses an exclusive lease per user but
        # specialized workers might have synchronization issues. Until we
        # compare the inconsistency rates of both approaches, we still run
        # AuthorizedProjectsWorker but with some delay and lower urgency as a
        # safety net.
        shared_with_group.refresh_members_authorized_projects(
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )
      end
    end
  end
end

Projects::GroupLinks::CreateService.prepend_mod_with('Projects::GroupLinks::CreateService')
