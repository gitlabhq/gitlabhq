# frozen_string_literal: true

# Removes temporary index to fix orphan promoted issues.
# For more information check: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23916
class RemoveTemporaryPromotedNotesIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :notes, 'tmp_idx_on_promoted_notes'
  end

  def down
    add_concurrent_index :notes,
      :note,
      where: "noteable_type = 'Issue' AND system IS TRUE AND note LIKE 'promoted to epic%'",
      name: 'tmp_idx_on_promoted_notes'
  end
end
