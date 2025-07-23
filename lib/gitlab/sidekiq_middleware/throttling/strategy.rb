# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      module Strategy
        StrategyStruct = Struct.new(:name, :concurrency_operator)

        SoftThrottle = StrategyStruct.new("SoftThrottle", ->(limit) { [(0.8 * limit).ceil, 1].max })
        HardThrottle = StrategyStruct.new("HardThrottle", ->(limit) { [(0.5 * limit).ceil, 1].max })

        GradualRecovery = StrategyStruct.new("GradualRecovery", ->(limit) { [limit + 1, (limit * 1.1).floor].max })

        # no-op
        None = StrategyStruct.new("None", nil)
      end
    end
  end
end
