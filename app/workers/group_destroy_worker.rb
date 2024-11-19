# frozen_string_literal: true

class GroupDestroyWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :groups_and_projects

  idempotent!
  deduplicate :until_executed, ttl: 2.hours

  def perform(group_id, user_id, params = {}) # rubocop:disable Lint/UnusedMethodArgument -- Keep params parameter for backwards compatibility. Remove `param` in 18.0 release.
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464673')

    begin
      group = Group.find(group_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    # AdjournedGroupDeletionWorker will destroy groups days after they are scheduled for deletion.
    # If admin_mode is enabled, it will potentially halt group and project deletion.
    # The admin_mode flag allows bypassing this check (but no other policy checks), since the admin_mode
    # check should have been run when the job was scheduled, not whenever Sidekiq gets around to it.
    Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode(user) do
      Groups::DestroyService.new(group, user).execute
    end
  end
end
