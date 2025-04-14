# frozen_string_literal: true

class AddListsProjectIdInvalidFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :lists,
      :projects,
      column: :project_id,
      target_column: :id,
      reverse_lock_order: true,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :lists, column: :project_id
    end
  end
end
