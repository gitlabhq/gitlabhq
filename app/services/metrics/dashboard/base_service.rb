# frozen_string_literal: true

# Searches a projects repository for a metrics dashboard and formats the output.
# Expects any custom dashboards will be located in `.gitlab/dashboards`
module Metrics
  module Dashboard
    class BaseService < ::BaseService
      include Gitlab::Metrics::Dashboard::Errors

      STAGES = ::Gitlab::Metrics::Dashboard::Stages
      SEQUENCE = [
        STAGES::CommonMetricsInserter,
        STAGES::EndpointInserter,
        STAGES::PanelIdsInserter,
        STAGES::Sorter,
        STAGES::AlertsInserter
      ].freeze

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
        return false unless params[:environment]

        project&.feature_available?(:metrics_dashboard, current_user)
      end

      # Returns a new dashboard Hash, supplemented with DB info
      def process_dashboard
        # Get the dashboard from cache/disk before beginning the benchmark.
        dashboard = raw_dashboard
        processed_dashboard = nil

        benchmark_processing do
          processed_dashboard = ::Gitlab::Metrics::Dashboard::Processor
            .new(project, dashboard, sequence, process_params)
            .process
        end

        processed_dashboard
      end

      def benchmark_processing
        output = nil

        processing_time_seconds = Benchmark.realtime { output = yield }

        if output
          processing_time_metric.observe(
            processing_time_metric_labels,
            processing_time_seconds * 1_000
          )
        end
      end

      def process_params
        params
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

      def sequence
        SEQUENCE
      end

      def processing_time_metric
        @processing_time_metric ||= ::Gitlab::Metrics.summary(
          :gitlab_metrics_dashboard_processing_time_ms,
          'Metrics dashboard processing time in milliseconds'
        )
      end

      def processing_time_metric_labels
        {
          stages: sequence_string,
          service: self.class.name
        }
      end

      # If @sequence is [STAGES::CommonMetricsInserter, STAGES::CustomMetricsInserter],
      # this function will output `CommonMetricsInserter-CustomMetricsInserter`.
      def sequence_string
        sequence.map { |stage_class| stage_class.to_s.split('::').last }.join('-')
      end
    end
  end
end
