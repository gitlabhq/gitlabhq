# frozen_string_literal: true

class FinalizeCiBuildNeedsShardingKeyBackfill < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '18.6'

  def up
    # NOTE: batched background job was enqueued for everyone but .com
    #       https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195899/diffs#diff-content-da790b060572ec350029ef3700b5b1e0665b0126
    return if Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProjectIdOnCiBuildNeeds',
      table_name: :ci_build_needs,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
