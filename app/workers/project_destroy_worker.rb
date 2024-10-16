# frozen_string_literal: true

class ProjectDestroyWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :source_code_management

  idempotent!
  deduplicate :until_executed, ttl: 2.hours

  def perform(project_id, user_id, params)
    params = params.symbolize_keys
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/333366')

    project = Project.find(project_id)
    user = User.find(user_id)

    # AdjournedProjectDeletionWorker will destroy projects days after they are scheduled for deletion.
    # If admin_mode is enabled, it will potentially halt group and project deletion.
    # The admin_mode flag allows bypassing this check (but no other policy checks), since the admin_mode
    # check should have been run when the job was scheduled, not whenever Sidekiq gets around to it.
    Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode(user) do
      ::Projects::DestroyService.new(project, user, params).execute
    end
  rescue ActiveRecord::RecordNotFound => error
    logger.error("Failed to delete project (#{project_id}): #{error.message}")
  end
end
