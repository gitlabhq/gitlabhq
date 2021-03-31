# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchMetrics
        attr_reader :timings

        def initialize
          @timings = {}
        end

        def time_operation(label)
          start_time = monotonic_time

          yield

          timings_for_label(label) << monotonic_time - start_time
        end

        private

        def timings_for_label(label)
          timings[label] ||= []
        end

        def monotonic_time
          Gitlab::Metrics::System.monotonic_time
        end
      end
    end
  end
end
