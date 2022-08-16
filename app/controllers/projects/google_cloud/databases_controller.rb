# frozen_string_literal: true

module Projects
  module GoogleCloud
    class DatabasesController < Projects::GoogleCloud::BaseController
      def index
        js_data = {
          configurationUrl: project_google_cloud_configuration_path(project),
          deploymentsUrl: project_google_cloud_deployments_path(project),
          databasesUrl: project_google_cloud_databases_path(project)
        }
        @js_data = js_data.to_json
        track_event('databases#index', 'success', js_data)
      end
    end
  end
end
