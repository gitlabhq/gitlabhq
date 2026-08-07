# frozen_string_literal: true

module Notifications
  module MobileDevicePushSubscriptions
    # Removes the user's subscriptions for a device token across all APNs
    # environments, so one sign-out clears both the sandbox and production
    # registrations of the device.
    class UnregisterService
      def initialize(user:, device_token:)
        @user = user
        @device_token = device_token
      end

      def execute
        deleted = user.mobile_device_push_subscriptions.with_device_token(device_token).delete_all

        return ServiceResponse.error(message: 'Push subscription not found', reason: :not_found) if deleted == 0

        ServiceResponse.success
      end

      private

      attr_reader :user, :device_token
    end
  end
end
