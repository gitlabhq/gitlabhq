# frozen_string_literal: true

class AddBoardAssigneesGroupIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_concurrent_foreign_key :board_assignees,
      :namespaces,
      column: :group_id,
      target_column: :id,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :board_assignees, column: :group_id
    end
  end
end
