# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class CacheCheck
        extend RedisAbstractCheck
      end
    end
  end
end
