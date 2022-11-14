# frozen_string_literal: true

class AddSupportingIndexForVulnerabilitiesFeedbackMigration < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "tmp_idx_for_vulnerability_feedback_migration"
  WHERE_CLAUSE = "migrated_to_state_transition = false AND feedback_type = 0"

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :vulnerability_feedback,
      %i[migrated_to_state_transition feedback_type],
      where: WHERE_CLAUSE,
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :vulnerability_feedback,
      INDEX_NAME
    )
  end
end
