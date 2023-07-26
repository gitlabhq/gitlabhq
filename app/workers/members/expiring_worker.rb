# frozen_string_literal: true

module Members
  class ExpiringWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    data_consistency :sticky
    feature_category :system_access
    urgency :low

    BATCH_LIMIT = 500

    def perform
      return unless Feature.enabled?(:member_expiring_email_notification)

      limit_date = Member::DAYS_TO_EXPIRE.days.from_now.to_date

      expiring_members = Member.active.where(users: { user_type: :human }).expiring_and_not_notified(limit_date) # rubocop: disable CodeReuse/ActiveRecord

      expiring_members.each_batch(of: BATCH_LIMIT) do |members|
        members.pluck_primary_key.each do |member_id|
          Members::ExpiringEmailNotificationWorker.perform_async(member_id)
        end
      end
    end
  end
end
