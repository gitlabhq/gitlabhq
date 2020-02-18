# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTemporaryIndexToPromotionNotes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes,
      :note,
      where: "noteable_type = 'Issue' AND system IS TRUE AND note LIKE 'promoted to epic%'",
      name: 'tmp_idx_on_promoted_notes'
  end

  def down
    # NO OP
  end
end
