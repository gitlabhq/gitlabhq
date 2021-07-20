# frozen_string_literal: true

module Groups
  module GroupLinks
    class DestroyService < BaseService
      def execute(one_or_more_links, skip_authorization: false)
        unless skip_authorization || group && can?(current_user, :admin_group_member, group)
          return error('Not Found', 404)
        end

        links = Array(one_or_more_links)

        if GroupGroupLink.delete(links)
          Gitlab::AppLogger.info(
            "GroupGroupLinks with ids: #{links.map(&:id)} have been deleted.")

          groups_to_refresh = links.map(&:shared_with_group)
          groups_to_refresh.uniq.each do |group|
            group.refresh_members_authorized_projects(blocking: false, direct_members_only: true)
          end
        else
          Gitlab::AppLogger.info(
            "Failed to delete GroupGroupLinks with ids: #{links.map(&:id)}.")
        end
      end
    end
  end
end
