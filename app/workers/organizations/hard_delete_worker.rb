# frozen_string_literal: true

module Organizations
  class HardDeleteWorker
    include ApplicationWorker

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- destructive primary-DB writes must hit the primary, mirrors GroupDestroyWorker

    include ExceptionBacktrace

    feature_category :organization

    idempotent!
    deduplicate :until_executed, ttl: 2.hours

    def perform(organization_id, user_id)
      Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/594310')

      organization = Organizations::Organization.find_by_id(organization_id)
      return log_skip(organization_id, user_id, 'organization not found') unless organization

      user = User.find_by_id(user_id)
      return log_skip(organization_id, user_id, 'user not found') unless user

      result = Organizations::HardDeleteService.new(organization, current_user: user).execute

      return unless result.error?

      # Surface the failure so Sidekiq doesn't silently report success and leave the
      # organization stuck in deletion_in_progress.
      Gitlab::AppLogger.warn(build_structured_payload(
        message: 'Organization hard deletion service returned an error',
        Labkit::Fields::GL_ORGANIZATION_ID => organization_id,
        Labkit::Fields::GL_USER_ID => user_id,
        error_message: result.message
      ))
    end

    private

    def log_skip(organization_id, user_id, reason)
      Gitlab::AppLogger.info(build_structured_payload(
        message: "Organization hard deletion skipped: #{reason}",
        Labkit::Fields::GL_ORGANIZATION_ID => organization_id,
        Labkit::Fields::GL_USER_ID => user_id
      ))
    end
  end
end
