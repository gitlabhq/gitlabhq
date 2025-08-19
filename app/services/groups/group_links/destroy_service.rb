# frozen_string_literal: true

module Groups
  module GroupLinks
    class DestroyService < ::Groups::GroupLinks::BaseService
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

            if Feature.enabled?(:project_authorizations_update_in_background_for_group_shares, group.root_ancestor)
              AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker.perform_async(group.id,
                { 'priority' => priority_for_refresh, 'direct_members_only' => true })
            else
              group.refresh_members_authorized_projects(
                priority: priority_for_refresh,
                direct_members_only: true
              )
            end
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
