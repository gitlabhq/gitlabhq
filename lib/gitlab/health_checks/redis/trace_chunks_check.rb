# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class TraceChunksCheck
        extend RedisAbstractCheck
      end
    end
  end
end
