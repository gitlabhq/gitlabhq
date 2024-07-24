# frozen_string_literal: true

module Groups
  module GroupLinks
    class CreateService < ::Groups::BaseService
      include GroupLinkable

      def initialize(group, shared_with_group, user, params)
        @shared_with_group = shared_with_group

        super(group, user, params)
      end

      private

      delegate :root_ancestor, to: :group

      def valid_to_create?
        can?(current_user, :admin_group_member, group) &&
          can?(current_user, :read_group, shared_with_group) &&
          sharing_allowed?
      end

      def build_link
        remove_unallowed_params

        @link = GroupGroupLink.new(
          shared_group: group,
          shared_with_group: shared_with_group,
          group_access: params[:shared_group_access],
          expires_at: params[:expires_at],
          member_role_id: params[:member_role_id]
        )
      end

      def setup_authorizations
        shared_with_group.refresh_members_authorized_projects(direct_members_only: true)
      end
    end
  end
end

Groups::GroupLinks::CreateService.prepend_mod
