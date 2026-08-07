# frozen_string_literal: true

module Notifications
  module MobileDevicePushSubscriptions
    # Idempotent registration keyed on (device_token, apns_environment). A token
    # already registered by another user is reassigned to the new user: the
    # device changed hands, and APNs tokens identify the device, not the account.
    # Concurrent registrations of the same token race on the unique index; the
    # loser retries and updates the winner's row. Hand-rolled instead of
    # safe_find_or_create_by because that relies on a subtransaction
    # (Performance/ActiveRecordSubtransactionMethods).
    class RegisterService
      def initialize(user:, device_token:, apns_environment:, attributes: {})
        @user = user
        @device_token = device_token
        @apns_environment = apns_environment
        @attributes = attributes
      end

      def execute
        subscription = register

        if subscription.errors.any? || !subscription.persisted?
          ServiceResponse.error(
            message: subscription.errors.full_messages.to_sentence.presence || 'Failed to register push subscription',
            reason: :bad_request,
            payload: { subscription: subscription }
          )
        else
          ServiceResponse.success(payload: { subscription: subscription })
        end
      end

      private

      attr_reader :user, :device_token, :apns_environment, :attributes

      def register
        registration = attributes.merge(user: user, last_seen_at: Time.current)
        attempts = 0

        begin
          subscription = MobileDevicePushSubscription.find_or_initialize_for_device(device_token, apns_environment)
          subscription.assign_attributes(registration)
          subscription.save

          subscription
        rescue ActiveRecord::RecordNotUnique
          raise if (attempts += 1) > 1

          retry
        end
      end
    end
  end
end
