# frozen_string_literal: true

module SshKeys
  class ExpiredNotificationWorker
    include ApplicationWorker
    include CronjobQueue

    feature_category :compliance_management
    idempotent!

    def perform
      return unless ::Feature.enabled?(:ssh_key_expiration_email_notification, default_enabled: :yaml)

      User.with_ssh_key_expired_today.find_each do |user|
        with_context(user: user) do
          Gitlab::AppLogger.info "#{self.class}: Notifying User #{user.id} about expired ssh key(s)"

          keys = user.expired_today_and_unnotified_keys

          Keys::ExpiryNotificationService.new(user, { keys: keys }).execute
        end
      end
    end
  end
end
