# frozen_string_literal: true

module Members
  class ExpiringEmailNotificationWorker
    include ApplicationWorker
    include CronjobChildWorker

    data_consistency :always
    feature_category :system_access
    urgency :low
    idempotent!

    def perform(member_id)
      notification_service = NotificationService.new
      member = ::Member.find_by_id(member_id)

      return unless member
      return unless Feature.enabled?(:member_expiring_email_notification, member.source.root_ancestor)
      return if member.expiry_notified_at.present?

      with_context(user: member.user) do
        notification_service.member_about_to_expire(member)
        Gitlab::AppLogger.info(message: "Notifying user about expiring membership", member_id: member.id)

        member.update(expiry_notified_at: Time.current)
      end
    end
  end
end
