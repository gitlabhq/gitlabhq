# frozen_string_literal: true

# Searches a projects repository for a metrics dashboard and formats the output.
# Expects any custom dashboards will be located in `.gitlab/dashboards`
module Metrics
  module Dashboard
    class BaseService < ::BaseService
      include Gitlab::Metrics::Dashboard::Errors

      def get_dashboard
        return error('Insufficient permissions.', :unauthorized) unless allowed?

        success(dashboard: process_dashboard)
      rescue StandardError => e
        handle_errors(e)
      end

      # Summary of all known dashboards for the service.
      # @return [Array<Hash>] ex) [{ path: String, default: Boolean }]
      def self.all_dashboard_paths(_project)
        raise NotImplementedError
      end

      # Returns an un-processed dashboard from the cache.
      def raw_dashboard
        Gitlab::Metrics::Dashboard::Cache.fetch(cache_key) { get_raw_dashboard }
      end

      private

      # Determines whether users should be able to view
      # dashboards at all.
      def allowed?
        Ability.allowed?(current_user, :read_environment, project)
      end

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
      # @return [Boolean]
      def insert_project_metrics?
        false
      end
    end
  end
end
