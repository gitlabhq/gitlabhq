# frozen_string_literal: true

class RemoveCdDeploymentsLegacyColumns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_deployments
  UNIQUE_INDEX_NAME = :index_cd_deployments_on_rollout_id_and_version_set_entry_id
  VSE_INDEX_NAME = :index_cd_deployments_on_version_set_entry_id

  def up
    with_lock_retries do
      remove_column TABLE_NAME, :rollout_id, if_exists: true
      remove_column TABLE_NAME, :version_set_entry_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :rollout_id, :bigint unless column_exists?(TABLE_NAME, :rollout_id)
      add_column TABLE_NAME, :version_set_entry_id, :bigint unless column_exists?(TABLE_NAME, :version_set_entry_id)
    end

    add_concurrent_index TABLE_NAME, [:rollout_id, :version_set_entry_id],
      unique: true, name: UNIQUE_INDEX_NAME
    add_concurrent_index TABLE_NAME, :version_set_entry_id, name: VSE_INDEX_NAME
  end
end
