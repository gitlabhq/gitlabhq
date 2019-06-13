# frozen_string_literal: true

# Searches a projects repository for a metrics dashboard and formats the output.
# Expects any custom dashboards will be located in `.gitlab/dashboards`
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class ProjectDashboardService < Gitlab::Metrics::Dashboard::BaseService
        DASHBOARD_ROOT = ".gitlab/dashboards"

        class << self
          def all_dashboard_paths(project)
            file_finder(project)
              .list_files_for(DASHBOARD_ROOT)
              .map { |filepath| { path: filepath, default: false } }
          end

          def file_finder(project)
            Gitlab::Template::Finders::RepoTemplateFinder.new(project, DASHBOARD_ROOT, '.yml')
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
end
