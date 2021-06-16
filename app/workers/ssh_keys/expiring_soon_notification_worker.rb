# frozen_string_literal: true

module SshKeys
  class ExpiringSoonNotificationWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue

    feature_category :compliance_management
    tags :exclude_from_kubernetes
    idempotent!

    def perform
      # rubocop:disable CodeReuse/ActiveRecord
      User.with_ssh_key_expiring_soon.find_each(batch_size: 10_000) do |user|
        with_context(user: user) do
          Gitlab::AppLogger.info "#{self.class}: Notifying User #{user.id} about expiring soon ssh key(s)"

          keys = user.expiring_soon_and_unnotified_keys

          Keys::ExpiryNotificationService.new(user, { keys: keys, expiring_soon: true }).execute
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
