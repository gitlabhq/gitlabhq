# frozen_string_literal: true

module Gitlab
  module Ci
    module Artifacts
      class Metrics
        include Gitlab::Utils::StrongMemoize

        def increment_destroyed_artifacts(size)
          destroyed_artifacts_counter.increment({}, size.to_i)
        end

        private

        def destroyed_artifacts_counter
          strong_memoize(:destroyed_artifacts_counter) do
            name = :destroyed_job_artifacts_count_total
            comment = 'Counter of destroyed expired job artifacts'

            ::Gitlab::Metrics.counter(name, comment)
          end
        end
      end
    end
  end
end
