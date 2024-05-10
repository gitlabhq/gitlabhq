# frozen_string_literal: true

class AddForeignKeyFromPipelineToCiBuildsToExecutionConfigs < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key(
      :p_ci_builds_execution_configs, :ci_pipelines,
      name: :fk_rails_c26408d02c, column: :pipeline_id,
      on_delete: :cascade, reverse_lock_order: true
    )
  end

  def down
    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(
        :p_ci_builds_execution_configs, :ci_pipelines,
        name: :fk_rails_c26408d02c, reverse_lock_order: true
      )
    end
  end
end
