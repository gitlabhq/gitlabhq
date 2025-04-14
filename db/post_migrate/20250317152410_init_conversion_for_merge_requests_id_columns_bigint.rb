# frozen_string_literal: true

class InitConversionForMergeRequestsIdColumnsBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  TABLE = :merge_requests
  COLUMNS = %i[latest_merge_request_diff_id assignee_id author_id id last_edited_by_id merge_user_id milestone_id
    source_project_id target_project_id updated_by_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
