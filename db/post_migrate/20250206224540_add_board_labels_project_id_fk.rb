# frozen_string_literal: true

class AddBoardLabelsProjectIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_concurrent_foreign_key :board_labels,
      :projects,
      column: :project_id,
      target_column: :id,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :board_labels, column: :project_id
    end
  end
end
