# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      ALL_INSTANCE_CHECKS =
        ::Gitlab::Redis::ALL_CLASSES.map do |instance_class|
          check_class = Class.new
          check_class.extend(RedisAbstractCheck)
          const_set("#{instance_class.store_name}Check", check_class)

          check_class
        end
    end
  end
end
