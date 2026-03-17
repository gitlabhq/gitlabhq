# frozen_string_literal: true

class RemoveLfsObjectsProjectsLfsObjectIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  FOREIGN_KEY_NAME = "fk_a56e02279c"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:lfs_objects_projects, :lfs_objects,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:lfs_objects_projects, :lfs_objects,
      name: FOREIGN_KEY_NAME, column: :lfs_object_id,
      on_delete: :restrict, validate: false)
  end
end
