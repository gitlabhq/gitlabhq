# frozen_string_literal: true

class AddPromotedToEpicForeignKeyToWorkItemTransitions < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_transitions, :epics, column: :promoted_to_epic_id,
      on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_transitions, column: :promoted_to_epic_id
    end
  end
end
