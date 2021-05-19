# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      class Metrics
        def self.pipeline_creation_duration_histogram
          name = :gitlab_ci_pipeline_creation_duration_seconds
          comment = 'Pipeline creation duration'
          labels = {}
          buckets = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 20.0, 50.0, 240.0]

          ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
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
          buckets = [0, 1, 5, 10, 20, 50, 100, 200, 500, 1000]

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

        def self.legacy_update_jobs_counter
          name = :ci_legacy_update_jobs_as_retried_total
          comment = 'Counter of occurrences when jobs were not being set as retried before update_retried'

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

        def ci_minutes_exceeded_builds_counter
          name = :ci_minutes_exceeded_builds_counter
          comment = 'Count of builds dropped due to CI minutes exceeded'

          Gitlab::Metrics.counter(name, comment)
        end

        def self.gitlab_ci_difference_live_vs_actual_minutes
          name = :gitlab_ci_difference_live_vs_actual_minutes
          comment = 'Comparison between CI minutes consumption from live tracking vs actual consumption'
          labels = {}
          buckets = [-120.0, -60.0, -30.0, -10.0, -5.0, -3.0, -1.0, 0.0, 1.0, 3.0, 5.0, 10.0, 30.0, 60.0, 120.0]
          ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
        end
      end
    end
  end
end
