# frozen_string_literal: true

module Projects
  module GroupLinks
    class UpdateService < BaseService
      def initialize(group_link, user = nil)
        super(group_link.project, user)

        @group_link = group_link
      end

      def execute(group_link_params)
        allowed_params = filter_params(group_link_params)

        if group_link.blank? || !allowed_to_update?
          return ServiceResponse.error(message: 'Not found', reason: :not_found)
        end

        unless allowed_to_update_to_or_from_owner?(allowed_params)
          return ServiceResponse.error(message: 'Forbidden', reason: :forbidden)
        end

        group_link.update!(allowed_params)

        refresh_authorizations if requires_authorization_refresh?(allowed_params)

        ServiceResponse.success
      end

      private

      attr_reader :group_link

      def permitted_attributes
        %i[group_access expires_at].freeze
      end

      def filter_params(params)
        params.select { |k| permitted_attributes.include?(k.to_sym) }
      end

      def allowed_to_update?
        current_user.can?(:admin_project_member, group_link.project)
      end

      def allowed_to_update_to_or_from_owner?(params)
        return current_user.can?(:manage_owners, group_link) if upgrading_to_owner?(params) || touching_an_owner?

        true
      end

      def refresh_authorizations
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)

        # Until we compare the inconsistency rates of the new specialized worker and
        # the old approach, we still run AuthorizedProjectsWorker
        # but with some delay and lower urgency as a safety net.
        group_link.group.refresh_members_authorized_projects(
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )
      end

      def requires_authorization_refresh?(params)
        params.include?(:group_access)
      end

      def upgrading_to_owner?(params)
        params[:group_access].to_i == Gitlab::Access::OWNER
      end

      def touching_an_owner?
        group_link.owner_access?
      end
    end
  end
end

Projects::GroupLinks::UpdateService.prepend_mod
