# frozen_string_literal: true

class AddSyncIndexOnExecutionConfigIdInCiBuilds < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '17.1'

  INDEX_NAME = 'index_p_ci_builds_on_execution_config_id'
  COLUMNS = [:execution_config_id]

  def up
    add_concurrent_partitioned_index(:p_ci_builds, COLUMNS, name: INDEX_NAME, where: "execution_config_id IS NOT NULL")
  end

  def down
    remove_concurrent_partitioned_index_by_name(:p_ci_builds, INDEX_NAME)
  end
end
