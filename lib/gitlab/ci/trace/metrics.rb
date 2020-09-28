# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      class Metrics
        extend Gitlab::Utils::StrongMemoize

        OPERATIONS = [:appended, :streamed, :chunked, :mutated, :overwrite,
                      :accepted, :finalized, :discarded, :conflict, :locked,
                      :invalid].freeze

        def increment_trace_operation(operation: :unknown)
          unless OPERATIONS.include?(operation)
            raise ArgumentError, "unknown trace operation: #{operation}"
          end

          self.class.trace_operations.increment(operation: operation)
        end

        def increment_trace_bytes(size)
          self.class.trace_bytes.increment({}, size.to_i)
        end

        def self.trace_operations
          strong_memoize(:trace_operations) do
            name = :gitlab_ci_trace_operations_total
            comment = 'Total amount of different operations on a build trace'

            Gitlab::Metrics.counter(name, comment)
          end
        end

        def self.trace_bytes
          strong_memoize(:trace_bytes) do
            name = :gitlab_ci_trace_bytes_total
            comment = 'Total amount of build trace bytes transferred'

            Gitlab::Metrics.counter(name, comment)
          end
        end
      end
    end
  end
end
