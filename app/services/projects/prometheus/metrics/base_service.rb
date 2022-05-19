# frozen_string_literal: true

module Projects
  module Prometheus
    module Metrics
      class BaseService
        include Gitlab::Utils::StrongMemoize

        def initialize(metric, params = {})
          @metric = metric
          @params = params.dup
        end

        protected

        attr_reader :metric, :params
      end
    end
  end
end
