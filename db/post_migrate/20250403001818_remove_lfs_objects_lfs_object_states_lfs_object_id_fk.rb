# frozen_string_literal: true

class RemoveLfsObjectsLfsObjectStatesLfsObjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_4188448cd5"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:lfs_object_states, :lfs_objects,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:lfs_object_states, :lfs_objects,
      name: FOREIGN_KEY_NAME, column: :lfs_object_id,
      target_column: :id, on_delete: :cascade)
  end
end
