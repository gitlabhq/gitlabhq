# frozen_string_literal: true

class MemberInvitationReminderEmailsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :subgroups
  urgency :low

  def perform
    return unless Gitlab::Experimentation.enabled?(:invitation_reminders)

    # To keep this MR small, implementation will be done in another MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42981/diffs?commit_id=8063606e0f83957b2dd38d660ee986f24dee6138
  end
end
