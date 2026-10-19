# frozen_string_literal: true

module Gitlab
  module MobilePush
    # A user as a push target: the checks every push asks before a send and
    # the registered phones. Expects the subscriptions to be preloaded.
    class Recipient
      attr_reader :user

      def initialize(user)
        @user = user
      end

      # Why no push may go to this user right now, or nil when one may.
      def skip_reason
        return :skipped_user_inactive unless user&.active?
        return :skipped_setting_disabled unless Feature.enabled?(:mobile_push_notifications, user)

        :skipped_no_subscription if subscriptions.empty?
      end

      def subscriptions
        @subscriptions ||= user.mobile_device_push_subscriptions.to_a
      end
    end
  end
end
