# frozen_string_literal: true

class AddDuplicatedToForeignKeyToWorkItemTransitions < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_transitions, :issues, column: :duplicated_to_id,
      on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_transitions, column: :duplicated_to_id
    end
  end
end
