# frozen_string_literal: true

class AddGroupSecretRotationInfosGroupFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :group_secret_rotation_infos, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :group_secret_rotation_infos, column: :group_id
    end
  end
end
