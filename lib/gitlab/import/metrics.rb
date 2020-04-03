# frozen_string_literal: true

# Prepend `Gitlab::Import::Metrics` to a class in order
# to measure and emit `Gitlab::Metrics` metrics of specified methods.
#
# @example
#   class Importer
#     prepend Gitlab::Import::Metrics
#
#     Gitlab::ImportExport::Metrics.measure :execute, metrics: {
#       importer_counter: {
#         type: :counter,
#         description: 'counter'
#       },
#       importer_histogram: {
#         type: :histogram,
#         labels: { importer: 'importer' },
#         description: 'histogram'
#       }
#     }
#
#     def execute
#        ...
#     end
#   end
#
# Each call to `#execute` increments `importer_counter` as well as
# measures `#execute` duration and reports histogram `importer_histogram`
module Gitlab
  module Import
    module Metrics
      def self.measure(method_name, metrics:)
        define_method "#{method_name}" do |*args|
          start_time = Time.zone.now

          result = super(*args)

          end_time = Time.zone.now

          report_measurement_metrics(metrics, end_time - start_time)

          result
        end
      end

      def report_measurement_metrics(metrics, duration)
        metrics.each do |metric_name, metric_value|
          case metric_value[:type]
          when :counter
            Gitlab::Metrics.counter(metric_name, metric_value[:description]).increment
          when :histogram
            Gitlab::Metrics.histogram(metric_name, metric_value[:description]).observe(metric_value[:labels], duration)
          else
            nil
          end
        end
      end
    end
  end
end
