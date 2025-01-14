# frozen_string_literal: true

module Users
  module SupportPin
    class UpdateService < SupportPin::BaseService
      def execute
        pin = generate_pin
        expiration = SUPPORT_PIN_EXPIRATION

        if store_pin(pin, expiration)
          { status: :success, pin: pin, expires_at: expiration }
        else
          { status: :error, message: 'Failed to create support PIN' }
        end
      end

      private

      def generate_pin
        SecureRandom.random_number(100000..999999).to_s
      end

      def store_pin(pin, expiration)
        Gitlab::Redis::Cache.with do |redis|
          key = pin_key
          redis.set(key, pin)
          redis.expireat(key, expiration.to_i)
        end
      end
    end
  end
end
