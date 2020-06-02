# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Metrics
          include Gitlab::Utils::StrongMemoize

          def pipeline_creation_duration_histogram
            strong_memoize(:pipeline_creation_duration_histogram) do
              name = :gitlab_ci_pipeline_creation_duration_seconds
              comment = 'Pipeline creation duration'
              labels = {}
              buckets = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 20.0, 50.0, 240.0]

              ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
            end
          end

          def pipeline_size_histogram
            strong_memoize(:pipeline_size_histogram) do
              name = :gitlab_ci_pipeline_size_builds
              comment = 'Pipeline size'
              labels = { source: nil }
              buckets = [0, 1, 5, 10, 20, 50, 100, 200, 500, 1000]

              ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
            end
          end
        end
      end
    end
  end
end
