# frozen_string_literal: true

module Gitlab
  module Import
    class Metrics
      include Gitlab::Utils::UsageData

      IMPORT_DURATION_BUCKETS = [0.5, 1, 3, 5, 10, 60, 120, 240, 360, 720, 1440].freeze

      attr_reader :importer, :duration

      def initialize(importer, project)
        @importer = importer
        @project = project
      end

      def track_start_import
        return unless project.github_import?

        track_usage_event(:github_import_project_start, project.id)
      end

      def track_finished_import
        @duration = Time.zone.now - project.created_at

        observe_histogram
        projects_counter.increment
        track_finish_metric
      end

      def track_failed_import
        return unless project.github_import?

        track_usage_event(:github_import_project_failure, project.id)
        track_import_state('github', 'Import::GithubService')
      end

      def track_canceled_import
        return unless project.github_import?

        track_usage_event(:github_import_project_cancelled, project.id)
        track_import_state('github', 'Import::GithubService')
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

      attr_reader :project

      def duration_histogram
        @duration_histogram ||= Gitlab::Metrics.histogram(
          :"#{importer}_total_duration_seconds",
          'Total time spent importing projects, in seconds',
          {},
          IMPORT_DURATION_BUCKETS
        )
      end

      def projects_counter
        @projects_counter ||= Gitlab::Metrics.counter(
          :"#{importer}_imported_projects_total",
          'The number of imported projects'
        )
      end

      def observe_histogram
        duration_histogram.observe({ importer: importer }, duration)
      end

      def track_finish_metric
        return unless project.github_import?

        track_import_state('github', 'Import::GithubService')

        case project.beautified_import_status_name
        when 'partially completed'
          track_usage_event(:github_import_project_partially_completed, project.id)
        when 'completed'
          track_usage_event(:github_import_project_success, project.id)
        end
      end

      def track_import_state(type, category)
        Gitlab::Tracking.event(
          category,
          'create',
          label: "#{type}_import_project_state",
          project: project,
          import_type: type,
          state: project.beautified_import_status_name
        )
      end
    end
  end
end
