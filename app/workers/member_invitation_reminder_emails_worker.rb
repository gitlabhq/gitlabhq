# frozen_string_literal: true

class MemberInvitationReminderEmailsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :subgroups
  urgency :low

  def perform
    return unless Gitlab::Experimentation.enabled?(:invitation_reminders)

    Member.not_accepted_invitations.not_expired.last_ten_days_excluding_today.find_in_batches do |invitations|
      invitations.each do |invitation|
        Members::InvitationReminderEmailService.new(invitation).execute
      end
    end
  end
end
