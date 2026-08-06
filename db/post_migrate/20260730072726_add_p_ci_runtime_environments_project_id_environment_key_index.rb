# frozen_string_literal: true

class AddPCiRuntimeEnvironmentsProjectIdEnvironmentKeyIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.3'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_runtime_environments
  INDEX_NAME = :idx_p_ci_runtime_environments_on_project_id_environment_key

  def up
    add_concurrent_partitioned_index TABLE_NAME, [:project_id, :environment_key], name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE_NAME, INDEX_NAME
  end
end
