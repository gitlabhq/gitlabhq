# frozen_string_literal: true

# Searches a projects repository for a metrics dashboard and formats the output.
# Expects any custom dashboards will be located in `.gitlab/dashboards`
module Gitlab
  module Metrics
    module Dashboard
      class BaseService < ::BaseService
        PROCESSING_ERROR = Gitlab::Metrics::Dashboard::Stages::BaseStage::DashboardProcessingError

        def get_dashboard
          return error("#{dashboard_path} could not be found.", :not_found) unless path_available?

          success(dashboard: process_dashboard)
        rescue PROCESSING_ERROR => e
          error(e.message, :unprocessable_entity)
        end

        # Summary of all known dashboards for the service.
        # @return [Array<Hash>] ex) [{ path: String, default: Boolean }]
        def all_dashboard_paths(_project)
          raise NotImplementedError
        end

        private

        # Returns a new dashboard Hash, supplemented with DB info
        def process_dashboard
          Gitlab::Metrics::Dashboard::Processor
            .new(project, params[:environment], raw_dashboard)
            .process(insert_project_metrics: insert_project_metrics?)
        end

        # @return [String] Relative filepath of the dashboard yml
        def dashboard_path
          params[:dashboard_path]
        end

        # Returns an un-processed dashboard from the cache.
        def raw_dashboard
          Rails.cache.fetch(cache_key) { get_raw_dashboard }
        end

        # @return [Hash] an unmodified dashboard
        def get_raw_dashboard
          raise NotImplementedError
        end

        # @return [String]
        def cache_key
          raise NotImplementedError
        end

        # Determines whether custom metrics should be included
        # in the processed output.
        def insert_project_metrics?
          false
        end

        # Checks if dashboard path exists or should be rejected
        # as a result of file-changes to the project repository.
        # @return [Boolean]
        def path_available?
          available_paths = Gitlab::Metrics::Dashboard::Finder.find_all_paths(project)

          available_paths.any? do |path_params|
            path_params[:path] == dashboard_path
          end
        end
      end
    end
  end
end
