# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class SharedStateCheck
        extend RedisAbstractCheck
      end
    end
  end
end
