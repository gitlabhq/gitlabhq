# frozen_string_literal: true

module Gitlab
  module Ci
    module Runner
      class Metrics
        extend Gitlab::Utils::StrongMemoize

        def increment_runner_authentication_success_counter(runner_type: 'unknown_type')
          raise ArgumentError, "unknown runner type: #{runner_type}" unless
            ::Ci::Runner.runner_types.include? runner_type

          self.class.runner_authentication_success_counter.increment(runner_type: runner_type)
        end

        def increment_runner_authentication_failure_counter
          self.class.runner_authentication_failure_counter.increment
        end

        def self.runner_authentication_success_counter
          strong_memoize(:runner_authentication_success) do
            name = :gitlab_ci_runner_authentication_success_total
            comment = 'Runner authentication success'
            labels = { runner_type: nil }

            ::Gitlab::Metrics.counter(name, comment, labels)
          end
        end

        def self.runner_authentication_failure_counter
          strong_memoize(:runner_authentication_failure) do
            name = :gitlab_ci_runner_authentication_failure_total
            comment = 'Runner authentication failure'

            ::Gitlab::Metrics.counter(name, comment)
          end
        end
      end
    end
  end
end
