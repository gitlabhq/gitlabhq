# frozen_string_literal: true

module SshKeys
  class ExpiredNotificationWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue

    feature_category :compliance_management
    tags :exclude_from_kubernetes
    idempotent!

    def perform
      return unless ::Feature.enabled?(:ssh_key_expiration_email_notification, default_enabled: :yaml)

      # rubocop:disable CodeReuse/ActiveRecord
      User.with_ssh_key_expired_today.find_each(batch_size: 10_000) do |user|
        with_context(user: user) do
          Gitlab::AppLogger.info "#{self.class}: Notifying User #{user.id} about expired ssh key(s)"

          keys = user.expired_today_and_unnotified_keys

          Keys::ExpiryNotificationService.new(user, { keys: keys, expiring_soon: false }).execute
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
