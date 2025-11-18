# frozen_string_literal: true

class RemoveWebHooksIndexOnServiceHookIntegrationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_web_hooks_on_service_hook_integration_id'

  def up
    remove_concurrent_index_by_name :web_hooks, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :web_hooks,
      :id,
      where: "integration_id IS NOT NULL AND type = 'ServiceHook'",
      name: INDEX_NAME
    )
  end
end
