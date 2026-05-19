# frozen_string_literal: true

class FinalizeBackfillWebHookLogsDailyShardingKeys < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # NOTE: Targeting all deployments other than gitlab.com to mirror
    #       the background migration https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215236/diffs#f6d4256a2ff43851f640abdafe3a35acc1e0e53b_0_16
    return if Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWebHookLogsDailyShardingKeys',
      table_name: :web_hook_logs_daily,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
