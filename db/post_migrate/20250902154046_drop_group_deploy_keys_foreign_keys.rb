# frozen_string_literal: true

class DropGroupDeployKeysForeignKeys < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  FK_GROUP_DEPLOY_KEYS = :fk_rails_c3854f19f5
  FK_NAMESPACES = :fk_rails_e87145115d
  FK_USERS = :fk_rails_5682fc07f8

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :group_deploy_keys_groups, name: FK_GROUP_DEPLOY_KEYS
    end
    with_lock_retries do
      remove_foreign_key_if_exists :group_deploy_keys_groups, name: FK_NAMESPACES
    end
    with_lock_retries do
      remove_foreign_key_if_exists :group_deploy_keys, name: FK_USERS
    end
  end

  def down
    add_concurrent_foreign_key(
      :group_deploy_keys, :users,
      column: :user_id,
      on_delete: :restrict,
      name: FK_USERS
    )
    add_concurrent_foreign_key(
      :group_deploy_keys_groups, :namespaces,
      column: :group_id,
      on_delete: :cascade,
      name: FK_NAMESPACES
    )
    add_concurrent_foreign_key(
      :group_deploy_keys_groups, :group_deploy_keys,
      column: :group_deploy_key_id,
      on_delete: :cascade,
      name: FK_GROUP_DEPLOY_KEYS
    )
  end
end
