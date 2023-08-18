# frozen_string_literal: true

class CreateTargetBranchRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :target_branch_rules do |t|
      t.timestamps_with_timezone null: false
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.text :name, null: false, limit: 255
      # rubocop:disable Migration/AddLimitToTextColumns
      # Branch names can be long so we allow for a large number of characters
      t.text :target_branch, null: false
      # rubocop:enable Migration/AddLimitToTextColumns
    end
  end
end
