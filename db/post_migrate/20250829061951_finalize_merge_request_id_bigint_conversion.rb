# frozen_string_literal: true

class FinalizeMergeRequestIdBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.4'

  COLUMNS = %i[latest_merge_request_diff_id assignee_id author_id id last_edited_by_id merge_user_id milestone_id
    source_project_id target_project_id updated_by_id].freeze

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(
      'merge_requests',
      COLUMNS
    )
  end

  def down; end
end
