# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      class Metrics
        extend Gitlab::Utils::StrongMemoize

        def self.pipeline_creation_duration_histogram
          name = :gitlab_ci_pipeline_creation_duration_seconds
          comment = 'Pipeline creation duration'
          # @gitlab: boolean value - if project is gitlab-org/gitlab
          labels = { gitlab: false }
          buckets = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 20.0, 50.0, 240.0]

          ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
        end

        def self.pipeline_creation_step_duration_histogram
          strong_memoize(:pipeline_creation_step_histogram) do
            name = :gitlab_ci_pipeline_creation_step_duration_seconds
            comment = 'Duration of each pipeline creation step'
            labels = { step: nil }
            buckets = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 50.0, 240.0]

            ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end

        def self.pipeline_security_orchestration_policy_processing_duration_histogram
          name = :gitlab_ci_pipeline_security_orchestration_policy_processing_duration_seconds
          comment = 'Pipeline security orchestration policy processing duration'

          ::Gitlab::Metrics.histogram(name, comment)
        end

        def self.pipeline_size_histogram
          name = :gitlab_ci_pipeline_size_builds
          comment = 'Pipeline size'
          labels = { source: nil }
          buckets = [0, 1, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 3000]

          ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
        end

        def self.pipeline_age_histogram
          name = :gitlab_ci_pipeline_age_minutes
          comment = 'Pipeline age histogram'
          buckets = [5, 30, 120, 720, 1440, 7200, 21600, 43200, 86400, 172800, 518400, 1036800]
          #          5m 30m 2h   12h  24h   5d    15d    30d    60d    180d    360d    2y

          ::Gitlab::Metrics.histogram(name, comment, {}, buckets)
        end

        def self.active_jobs_histogram
          name = :gitlab_ci_active_jobs
          comment = 'Total amount of active jobs'
          labels = { plan: nil }
          buckets = [0, 200, 500, 1_000, 2_000, 5_000, 10_000, 15_000, 20_000, 30_000, 40_000]

          ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
        end

        def self.pipeline_builder_scoped_variables_histogram
          name = :gitlab_ci_pipeline_builder_scoped_variables_duration
          comment = 'Pipeline variables builder scoped_variables duration'
          labels = {}
          buckets = [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5, 10, 30, 60, 120]

          ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
        end

        def self.pipeline_processing_events_counter
          name = :gitlab_ci_pipeline_processing_events_total
          comment = 'Total amount of pipeline processing events'

          Gitlab::Metrics.counter(name, comment)
        end

        def self.pipelines_created_counter
          name = :pipelines_created_total
          comment = 'Counter of pipelines created'

          Gitlab::Metrics.counter(name, comment)
        end

        def self.pipeline_failure_reason_counter
          name = :gitlab_ci_pipeline_failure_reasons
          comment = 'Counter of pipeline failure reasons'

          Gitlab::Metrics.counter(name, comment)
        end

        def self.job_failure_reason_counter
          name = :gitlab_ci_job_failure_reasons
          comment = 'Counter of job failure reasons'

          Gitlab::Metrics.counter(name, comment)
        end

        def self.job_token_inbound_access_counter
          name = :gitlab_ci_job_token_inbound_access
          comment = 'Count of inbound accesses via CI job token'

          Gitlab::Metrics.counter(name, comment)
        end

        def self.duplicate_job_name_errors_counter
          name = :gitlab_ci_duplicate_job_name_errors_counter
          comment = 'Counter of duplicate job name errors'

          Gitlab::Metrics.counter(name, comment)
        end

        def ci_minutes_exceeded_builds_counter
          name = :ci_minutes_exceeded_builds_counter
          comment = 'Count of builds dropped due to compute minutes exceeded'

          Gitlab::Metrics.counter(name, comment)
        end
      end
    end
  end
end
