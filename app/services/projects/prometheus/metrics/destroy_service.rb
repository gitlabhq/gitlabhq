# frozen_string_literal: true

module Projects
  module Prometheus
    module Metrics
      class DestroyService < Metrics::BaseService
        def execute
          metric.destroy
        end
      end
    end
  end
end
