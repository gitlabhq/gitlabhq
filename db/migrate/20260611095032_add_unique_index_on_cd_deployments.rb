# frozen_string_literal: true

class AddUniqueIndexOnCdDeployments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_cd_deployments_on_rollout_env_id_and_service_id'

  def up
    add_concurrent_index :cd_deployments, [:rollout_environment_id, :service_id],
      unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_deployments, INDEX_NAME
  end
end
