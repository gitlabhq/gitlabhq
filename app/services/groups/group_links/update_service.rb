# frozen_string_literal: true

module Groups
  module GroupLinks
    class UpdateService < ::Groups::BaseService
      def initialize(group_link, user = nil)
        super(group_link.shared_group, user)

        @group_link = group_link
      end

      def execute(group_link_params)
        @group_link_params = group_link_params

        remove_unallowed_params

        group_link.update!(group_link_params)

        if requires_authorization_refresh?(group_link_params)
          group_link.shared_with_group.refresh_members_authorized_projects(direct_members_only: true)
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
