# frozen_string_literal: true

module Users
  module SupportPin
    class RetrieveService < SupportPin::BaseService
      def execute
        Gitlab::Redis::Cache.with do |redis|
          key = pin_key
          pin = redis.get(key)
          expires_at = redis.ttl(key)

          { pin: pin, expires_at: Time.zone.now + expires_at } if pin && expires_at > 0
        end
      end
    end
  end
end
