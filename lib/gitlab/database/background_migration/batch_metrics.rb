# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchMetrics
        attr_reader :timings
        attr_reader :affected_rows

        def initialize
          @timings = {}
          @affected_rows = {}
        end

        def time_operation(label, &blk)
          instrument_operation(label, instrument_affected_rows: false, &blk)
        end

        def instrument_operation(label, instrument_affected_rows: true)
          start_time = monotonic_time

          count = yield

          timings_for_label(label) << (monotonic_time - start_time)
          affected_rows_for_label(label) << count if instrument_affected_rows && count.is_a?(Integer)
        end

        private

        def timings_for_label(label)
          timings[label] ||= []
        end

        def affected_rows_for_label(label)
          affected_rows[label] ||= []
        end

        def monotonic_time
          Gitlab::Metrics::System.monotonic_time
        end
      end
    end
  end
end
