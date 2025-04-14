# frozen_string_literal: true

class BackfillMergeRequestsIdColumnsBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  TABLE = :merge_requests
  COLUMNS = %i[latest_merge_request_diff_id assignee_id author_id id last_edited_by_id merge_user_id milestone_id
    source_project_id target_project_id updated_by_id]
  SUB_BATCH_SIZE = 50
  BATCH_SIZE = 5000

  def up
    backfill_conversion_of_integer_to_bigint(
      TABLE, COLUMNS,
      sub_batch_size: SUB_BATCH_SIZE, batch_size: BATCH_SIZE
    )
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
