# frozen_string_literal: true

module Members
  class ExpiringEmailNotificationWorker
    include ApplicationWorker
    include CronjobChildWorker

    data_consistency :always
    feature_category :system_access
    urgency :low
    idempotent!

    attr_reader :member

    def perform(member_id)
      member = ::Member.including_user.including_source.find_by_id(member_id)

      return unless valid_for_notification?(member)

      with_context(user: member.user) do
        Members::AboutToExpireMailer.with(member: member).email.deliver_later # rubocop:disable CodeReuse/ActiveRecord -- false positive
        Gitlab::AppLogger.info(message: "Notifying user about expiring membership", member_id: member.id)

        member.update(expiry_notified_at: Time.current)
      end
    end

    def valid_for_notification?(member)
      member.expiry_notified_at.blank? &&
        member&.user.present? &&
        member.user.active? &&
        member.user.human?
    end
  end
end
