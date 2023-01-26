# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Instrumentation
        BUCKETS = [0.25, 1, 5, 10].freeze

        def parse!(...)
          parser_result = nil

          duration = Benchmark.realtime do
            parser_result = super
          end

          labels = {}

          histogram = Gitlab::Metrics.histogram(
            :ci_report_parser_duration_seconds,
            'Duration of parsing a CI report artifact',
            labels,
            BUCKETS
          )

          histogram.observe({ parser: self.class.name }, duration)

          parser_result
        end
      end
    end
  end
end
