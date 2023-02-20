# frozen_string_literal: true

class AddIndexForProtectedTagCreateAccessLevels < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  DEPLOY_KEY_INDEX_NAME = 'index_protected_tag_create_access_levels_on_deploy_key_id'

  def up
    add_concurrent_foreign_key :protected_tag_create_access_levels, :keys, column: :deploy_key_id, on_delete: :cascade
    add_concurrent_index :protected_tag_create_access_levels, :deploy_key_id,
                         name: DEPLOY_KEY_INDEX_NAME
  end

  def down
    remove_foreign_key_if_exists :protected_tag_create_access_levels, column: :deploy_key_id
    remove_concurrent_index_by_name :protected_tag_create_access_levels, name: DEPLOY_KEY_INDEX_NAME
  end
end
