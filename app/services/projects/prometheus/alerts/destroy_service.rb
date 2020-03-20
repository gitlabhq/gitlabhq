# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class DestroyService < BaseService
        def execute(alert)
          alert.destroy
        end
      end
    end
  end
end
