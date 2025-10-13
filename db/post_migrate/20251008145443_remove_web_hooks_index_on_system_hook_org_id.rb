# frozen_string_literal: true

class RemoveWebHooksIndexOnSystemHookOrgId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_web_hooks_on_system_hook_organization_id'

  def up
    remove_concurrent_index_by_name :web_hooks, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :web_hooks,
      :id,
      where: "organization_id IS NULL AND type = 'SystemHook'",
      name: INDEX_NAME
    )
  end
end
