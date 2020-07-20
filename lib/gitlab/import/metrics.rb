# frozen_string_literal: true

module Gitlab
  module Import
    class Metrics
      IMPORT_DURATION_BUCKETS = [0.5, 1, 3, 5, 10, 60, 120, 240, 360, 720, 1440].freeze

      attr_reader :importer

      def initialize(importer, project)
        @importer = importer
        @project = project
      end

      def track_finished_import
        duration = Time.zone.now - @project.created_at

        duration_histogram.observe({ importer: importer }, duration)
        projects_counter.increment
      end

      def projects_counter
        @projects_counter ||= Gitlab::Metrics.counter(
          :"#{importer}_imported_projects_total",
          'The number of imported projects'
        )
      end

      def issues_counter
        @issues_counter ||= Gitlab::Metrics.counter(
          :"#{importer}_imported_issues_total",
          'The number of imported issues'
        )
      end

      def merge_requests_counter
        @merge_requests_counter ||= Gitlab::Metrics.counter(
          :"#{importer}_imported_merge_requests_total",
          'The number of imported merge (pull) requests'
        )
      end

      private

      def duration_histogram
        @duration_histogram ||= Gitlab::Metrics.histogram(
          :"#{importer}_total_duration_seconds",
          'Total time spent importing projects, in seconds',
          {},
          IMPORT_DURATION_BUCKETS
        )
      end
    end
  end
end
