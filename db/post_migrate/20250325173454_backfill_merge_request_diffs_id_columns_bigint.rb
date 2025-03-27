# frozen_string_literal: true

class BackfillMergeRequestDiffsIdColumnsBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  TABLE = :merge_request_diffs
  COLUMNS = %i[id merge_request_id]
  SUB_BATCH_SIZE = 200
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
