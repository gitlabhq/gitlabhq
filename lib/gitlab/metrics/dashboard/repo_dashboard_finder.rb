# frozen_string_literal: true

# Provides methods to list and read dashboard yaml files from a project's repository.
module Gitlab
  module Metrics
    module Dashboard
      class RepoDashboardFinder
        DASHBOARD_ROOT = ".gitlab/dashboards"
        DASHBOARD_EXTENSION = '.yml'

        class << self
          # Returns list of all user-defined dashboard paths. Used to populate
          # Repository model cache (Repository#user_defined_metrics_dashboard_paths).
          # Also deletes all dashboard cache entries.
          # @return [Array] ex) ['.gitlab/dashboards/dashboard1.yml']
          def list_dashboards(project)
            Gitlab::Metrics::Dashboard::Cache.for(project).delete_all!

            file_finder(project).list_files_for(DASHBOARD_ROOT)
          end

          # Reads the given dashboard from repository, and returns the content as a string.
          # @return [String]
          def read_dashboard(project, dashboard_path)
            file_finder(project).read(dashboard_path)
          end

          private

          def file_finder(project)
            Gitlab::Template::Finders::RepoTemplateFinder.new(project, DASHBOARD_ROOT, DASHBOARD_EXTENSION)
          end
        end
      end
    end
  end
end
