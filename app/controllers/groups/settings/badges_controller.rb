module Groups
  module Settings
    class BadgesController < Groups::ApplicationController
      include GrapeRouteHelpers::NamedRouteMatcher

      before_action :authorize_admin_group!

      def index
        @badge_api_endpoint = api_v4_groups_badges_path(id: @group.id)
      end
    end
  end
end
