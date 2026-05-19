# frozen_string_literal: true

class CleanUpBigintConversionForMergeRequests < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  TABLE = :merge_requests
  COLUMNS = %i[
    assignee_id
    author_id
    id
    last_edited_by_id
    latest_merge_request_diff_id
    merge_user_id
    milestone_id
    source_project_id
    target_project_id
    updated_by_id
  ]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no op
  end
end
