# frozen_string_literal: true

module Ci
  module PrometheusMetrics
    class ObserveHistogramsService
      class << self
        def available_histograms
          @available_histograms ||= [
            histogram(:pipeline_graph_link_calculation_duration_seconds, 'Total time spent calculating links, in seconds', {}, [0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.8, 1, 2]),
            histogram(:pipeline_graph_links_total, 'Number of links per graph', {}, [1, 5, 10, 25, 50, 100, 200]),
            histogram(:pipeline_graph_links_per_job_ratio, 'Ratio of links to job per graph', {}, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
          ].to_h
        end

        private

        def histogram(name, *attrs)
          [name.to_s, proc { Gitlab::Metrics.histogram(name, *attrs) }]
        end
      end

      def initialize(project, params)
        @project = project
        @params = params
      end

      def execute
        params
          .fetch(:histograms, [])
          .each { |data| observe(data) }

        ServiceResponse.success(http_status: :created)
      end

      private

      attr_reader :project, :params

      def observe(data)
        histogram = find_histogram(data[:name])
        histogram.observe({}, data[:value].to_f)
      end

      def find_histogram(name)
        self.class.available_histograms
          .fetch(name) { raise ActiveRecord::RecordNotFound }
          .call
      end
    end
  end
end
