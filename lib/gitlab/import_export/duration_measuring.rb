# frozen_string_literal: true

module Gitlab
  module ImportExport
    module DurationMeasuring
      extend ActiveSupport::Concern

      included do
        attr_reader :duration_s

        def with_duration_measuring
          result = nil

          @duration_s = Benchmark.realtime do
            result = yield
          end

          result
        end
      end
    end
  end
end
