# frozen_string_literal: true

module Keys
  class ExpiryNotificationService < ::Keys::BaseService
    attr_accessor :keys

    def initialize(user, params)
      @keys = params[:keys]

      super
    end

    def execute
      return unless user.can?(:receive_notifications)

      notification_service.ssh_key_expired(user, keys.map(&:fingerprint))

      keys.update_all(expiry_notification_delivered_at: Time.current.utc)
    end
  end
end
