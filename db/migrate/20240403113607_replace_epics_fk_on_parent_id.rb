# frozen_string_literal: true

class ReplaceEpicsFkOnParentId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.11'

  NEW_FK_NAME = 'fk_epics_on_parent_id_with_on_delete_nullify'

  def up
    # This will replace the existing fk_25b99c1be3
    add_concurrent_foreign_key(
      :epics,
      :epics,
      column: :parent_id,
      on_delete: :nullify,
      validate: false,
      name: NEW_FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :epics,
        column: :parent_id,
        on_delete: :nullify,
        name: NEW_FK_NAME
      )
    end
  end
end
