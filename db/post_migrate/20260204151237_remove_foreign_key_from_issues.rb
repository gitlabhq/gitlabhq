# frozen_string_literal: true

class RemoveForeignKeyFromIssues < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_b37be69be6'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :issues, :work_item_types,
        column: :work_item_type_id, name: CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :issues, :work_item_types,
      column: :work_item_type_id, on_delete: nil, name: CONSTRAINT_NAME
  end
end
