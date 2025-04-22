# frozen_string_literal: true

module Users
  module SupportPin
    class BaseService
      SUPPORT_PIN_PREFIX = "support_pin"
      SUPPORT_PIN_EXPIRATION = 7.days.from_now

      def initialize(user)
        @user = user
      end

      def pin_key
        "#{SUPPORT_PIN_PREFIX}:#{@user.id}"
      end

      def pin_exists?
        Gitlab::Redis::Cache.with do |redis|
          redis.exists(pin_key).to_i > 0
        end
      end
    end
  end
end
