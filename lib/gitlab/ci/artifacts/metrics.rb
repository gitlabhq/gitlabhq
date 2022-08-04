# frozen_string_literal: true

module Gitlab
  module Ci
    module Artifacts
      class Metrics
        include Gitlab::Utils::StrongMemoize

        def self.build_completed_report_type_counter(report_type)
          name = "artifact_report_#{report_type}_builds_completed_total".to_sym
          comment = "Number of completed builds with #{report_type} report artifacts"

          ::Gitlab::Metrics.counter(name, comment)
        end

        def increment_destroyed_artifacts_count(size)
          destroyed_artifacts_counter.increment({}, size.to_i)
        end

        def increment_destroyed_artifacts_bytes(bytes)
          destroyed_artifacts_bytes_counter.increment({}, bytes)
        end

        private

        def destroyed_artifacts_counter
          strong_memoize(:destroyed_artifacts_counter) do
            name = :destroyed_job_artifacts_count_total
            comment = 'Counter of destroyed expired job artifacts'

            ::Gitlab::Metrics.counter(name, comment)
          end
        end

        def destroyed_artifacts_bytes_counter
          strong_memoize(:destroyed_artifacts_bytes_counter) do
            name = :destroyed_job_artifacts_bytes_total
            comment = 'Counter of bytes of destroyed expired job artifacts'

            ::Gitlab::Metrics.counter(name, comment)
          end
        end
      end
    end
  end
end
