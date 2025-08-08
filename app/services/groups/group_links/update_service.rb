# frozen_string_literal: true

module Groups
  module GroupLinks
    class UpdateService < ::Groups::GroupLinks::BaseService
      def initialize(group_link, user = nil)
        super(group_link.shared_group, user)

        @group_link = group_link
      end

      def execute(group_link_params)
        @group_link_params = group_link_params

        remove_unallowed_params

        group_link.update!(group_link_params)

        if requires_authorization_refresh?(group_link_params)
          shared_with_group = group_link.shared_with_group

          if Feature.enabled?(
            :project_authorizations_update_in_background_for_group_shares,
            shared_with_group.root_ancestor
          )
            AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker.perform_async(
              shared_with_group.id,
              { 'priority' => priority_for_refresh, 'direct_members_only' => true }
            )
          else
            shared_with_group.refresh_members_authorized_projects(
              priority: priority_for_refresh,
              direct_members_only: true
            )
          end
        end

        group_link
      end

      private

      attr_accessor :group_link, :group_link_params

      def requires_authorization_refresh?(params)
        params.include?(:group_access)
      end
    end
  end
end

Groups::GroupLinks::UpdateService.prepend_mod
