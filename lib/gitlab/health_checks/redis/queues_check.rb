# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class QueuesCheck
        extend RedisAbstractCheck
      end
    end
  end
end
