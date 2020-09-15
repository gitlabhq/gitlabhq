# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      class Metrics
        extend Gitlab::Utils::StrongMemoize

        OPERATIONS = [:appended, :mutated, :overwrite, :accepted,
                      :finalized, :discarded, :flaky].freeze

        def increment_trace_operation(operation: :unknown)
          unless OPERATIONS.include?(operation)
            raise ArgumentError, 'unknown trace operation'
          end

          self.class.trace_operations.increment(operation: operation)
        end

        def self.trace_operations
          strong_memoize(:trace_operations) do
            name = :gitlab_ci_trace_operations_total
            comment = 'Total amount of different operations on a build trace'

            Gitlab::Metrics.counter(name, comment)
          end
        end
      end
    end
  end
end
