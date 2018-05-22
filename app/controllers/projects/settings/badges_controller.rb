module Projects
  module Settings
    class BadgesController < Projects::ApplicationController
      include API::Helpers::RelatedResourcesHelpers

      before_action :authorize_admin_project!

      def index
        @badge_api_endpoint = expose_url(api_v4_projects_badges_path(id: @project.id))
      end
    end
  end
end
