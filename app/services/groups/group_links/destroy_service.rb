# frozen_string_literal: true

module Groups
  module GroupLinks
    class DestroyService < ::Groups::BaseService
      def execute(one_or_more_links, skip_authorization: false)
        unless skip_authorization || (group && can?(current_user, :admin_group_member, group))
          return error('Not Found', 404)
        end

        links = Array(one_or_more_links)

        if GroupGroupLink.delete(links)
          Gitlab::AppLogger.info(
            "GroupGroupLinks with ids: #{links.map(&:id)} have been deleted.")

          groups_to_refresh = links.map(&:shared_with_group)
          groups_to_refresh.uniq.each do |group|
            next if Feature.enabled?(:skip_group_share_unlink_auth_refresh, group.root_ancestor)

            group.refresh_members_authorized_projects(direct_members_only: true)
          end
        else
          Gitlab::AppLogger.info(
            "Failed to delete GroupGroupLinks with ids: #{links.map(&:id)}.")
        end

        links
      end
    end
  end
end

Groups::GroupLinks::DestroyService.prepend_mod
