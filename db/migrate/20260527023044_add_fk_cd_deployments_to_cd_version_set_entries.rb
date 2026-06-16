# frozen_string_literal: true

class AddFkCdDeploymentsToCdVersionSetEntries < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_concurrent_foreign_key :cd_deployments, :cd_version_set_entries,
      column: :version_set_entry_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_deployments, column: :version_set_entry_id
    end
  end
end
