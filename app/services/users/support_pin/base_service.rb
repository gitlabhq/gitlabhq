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
    end
  end
end
