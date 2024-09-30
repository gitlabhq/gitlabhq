# frozen_string_literal: true

module AntiAbuse
  class BanDuplicateUsersWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :instance_resiliency
    urgency :low

    def perform(banned_user_id)
      @banned_user = User.find_by_id(banned_user_id)
      return unless banned_user&.banned?

      ban_users_with_the_same_detumbled_email!
    end

    private

    attr_reader :banned_user

    def ban_users_with_the_same_detumbled_email!
      return unless Feature.enabled?(:auto_ban_via_detumbled_email, banned_user, type: :gitlab_com_derisk)

      reason = "User #{banned_user.id} was banned with the same detumbled email address"

      User.active.by_detumbled_emails(banned_user.verified_detumbled_emails).each do |user|
        user.with_lock do
          # Check the user state again in case it changed before acquiring the lock
          ban_user!(user, reason) if user.active?
        end
      end
    end

    def ban_user!(user, reason)
      user.ban!
      UserCustomAttribute.set_auto_banned_by(user: user, reason: reason)
      log_event(user, reason)
    end

    def log_event(user, reason)
      Gitlab::AppLogger.info(
        message: "Duplicate user auto-ban",
        reason: reason,
        username: user.username.to_s,
        user_id: user.id,
        email: user.email.to_s,
        triggered_by_banned_user_id: banned_user.id,
        triggered_by_banned_username: banned_user.username
      )
    end
  end
end

AntiAbuse::BanDuplicateUsersWorker.prepend_mod
