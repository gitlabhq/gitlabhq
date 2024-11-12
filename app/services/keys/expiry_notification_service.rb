# frozen_string_literal: true

module Keys
  class ExpiryNotificationService < ::Keys::BaseService
    attr_accessor :keys, :expiring_soon

    def initialize(user, params)
      @keys = params[:keys]
      @expiring_soon = params[:expiring_soon]

      super
    end

    def execute
      return unless allowed?

      if expiring_soon
        create_expiring_soon_todos
        trigger_expiring_soon_notification
      else
        create_expired_todos
        trigger_expired_notification
      end
    end

    private

    def allowed?
      user.can?(:receive_notifications)
    end

    def trigger_expiring_soon_notification
      notification_service.ssh_key_expiring_soon(user, keys.map(&:fingerprint))

      keys.update_all(before_expiry_notification_delivered_at: Time.current.utc)
    end

    def trigger_expired_notification
      notification_service.ssh_key_expired(user, keys.map(&:fingerprint))

      keys.update_all(expiry_notification_delivered_at: Time.current.utc)
    end

    def create_expiring_soon_todos
      todo_service.ssh_key_expiring_soon(keys)
    end

    def create_expired_todos
      todo_service.ssh_key_expired(keys)
    end
  end
end
