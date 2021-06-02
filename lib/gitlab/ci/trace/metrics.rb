# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      class Metrics
        extend Gitlab::Utils::StrongMemoize

        OPERATIONS = [
          :appended,  # new trace data has been written to a chunk
          :streamed,  # new trace data has been sent by a runner
          :chunked,   # new trace chunk has been created
          :mutated,   # trace has been mutated when removing secrets
          :accepted,  # scheduled chunks for migration and responded with 202
          :finalized, # all live build trace chunks have been persisted
          :discarded, # failed to persist live chunks before timeout
          :conflict,  # runner has sent unrecognized build state details
          :locked,    # build trace has been locked by a different mechanism
          :stalled,   # failed to migrate chunk due to a worker duplication
          :invalid,   # invalid build trace has been detected using CRC32
          :corrupted  # malformed trace found after comparing CRC32 and size
        ].freeze

        def increment_trace_operation(operation: :unknown)
          unless OPERATIONS.include?(operation)
            raise ArgumentError, "unknown trace operation: #{operation}"
          end

          self.class.trace_operations.increment(operation: operation)
        end

        def increment_trace_bytes(size)
          self.class.trace_bytes.increment({}, size.to_i)
        end

        def observe_migration_duration(seconds)
          self.class.finalize_histogram.observe({}, seconds.to_f)
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

        def self.finalize_histogram
          strong_memoize(:finalize_histogram) do
            name = :gitlab_ci_trace_finalize_duration_seconds
            comment = 'Duration of build trace chunks migration to object storage'
            buckets = [0.1, 0.5, 1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 20.0, 30.0, 60.0, 300.0]
            labels = {}

            ::Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end
      end
    end
  end
end
