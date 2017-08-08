# Used to instrument methods in the GitLab codebase
#
# Creates a lightweight wrapper around the method pointed at by DSL method call
# Under the hood this creates a Prometheus histogram, with at most 12 buckets to
# keep that instance alife. Labels are not supported yet, as the number of labels
# per histogram should remain limited, ideally to about 10. Also I didn't want
# an extra DSL method like grape as that gets messy real quick.
#
# Usage:
# class SomeClass
#   include Gitlab::Instrumentable
#
#   instrument_method :some_method
#
#   # with custom buckets, max 12
#   instrument_method :other_method, 20..30
#   instrument_method :other_method, [1,3,5,8,12,30,60,120]
# end
require 'active_support/concern'

module Gitlab
  module Instrumentable
    extend ActiveSupport::Concern

    class_methods do
      def instrument_method(method, buckets = nil)
        @buckets = buckets&.to_a || ::Prometheus::Client::Histogram::DEFAULT_BUCKETS
        raise 'Too many buckets, limit to 12' if @buckets.size > 12 && !Rails.env.production?

        mod = Module.new do
          define_method(method) do |*args|
            return super(*args) if Rails.env.test?

            start_time = Time.now.to_f
            res = super(*args)
            record_timing_since(start_time, __method__)

            res
          end

          private

          def record_timing_since(time, method)
            class_name = self.class.name
            @histogram ||=  Gitlab::Metrics.histogram(
              "#{class_name.underscore}_duration_seconds",
              "Execution time for #{class_name}##{method}",
              {}, @buckets)

            @histogram.observe({}, Time.now.to_f - time)
          end
        end

        self.prepend(mod)
      end
    end
  end
end
