# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class RateLimitingCheck
        extend RedisAbstractCheck
      end
    end
  end
end
