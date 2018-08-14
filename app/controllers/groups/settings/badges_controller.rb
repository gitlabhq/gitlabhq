module Groups
  module Settings
    class BadgesController < Groups::ApplicationController
      include API::Helpers::RelatedResourcesHelpers

      before_action :authorize_admin_group!

      def index
        @badge_api_endpoint = expose_url(api_v4_groups_badges_path(id: @group.id))
      end
    end
  end
end
