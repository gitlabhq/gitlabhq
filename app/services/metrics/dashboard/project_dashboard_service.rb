# frozen_string_literal: true

# Searches a projects repository for a metrics dashboard and formats the output.
# Expects any custom dashboards will be located in `.gitlab/dashboards`
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class ProjectDashboardService < ::Metrics::Dashboard::BaseService
      DASHBOARD_ROOT = ".gitlab/dashboards"

      class << self
        def all_dashboard_paths(project)
          file_finder(project)
            .list_files_for(DASHBOARD_ROOT)
            .map do |filepath|
              {
                path: filepath,
                display_name: name_for_path(filepath),
                default: false,
                system_dashboard: false
              }
            end
        end

        def file_finder(project)
          Gitlab::Template::Finders::RepoTemplateFinder.new(project, DASHBOARD_ROOT, '.yml')
        end

        # Grabs the filepath after the base directory.
        def name_for_path(filepath)
          filepath.delete_prefix("#{DASHBOARD_ROOT}/")
        end
      end

      private

      # Searches the project repo for a custom-defined dashboard.
      def get_raw_dashboard
        yml = self.class.file_finder(project).read(dashboard_path)

        YAML.safe_load(yml)
      end

      def cache_key
        "project_#{project.id}_metrics_dashboard_#{dashboard_path}"
      end
    end
  end
end
