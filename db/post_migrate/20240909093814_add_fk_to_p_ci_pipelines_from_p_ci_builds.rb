# frozen_string_literal: true

class AddFkToPCiPipelinesFromPCiBuilds < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.4'
  disable_ddl_transaction!

  FK_NAME = :fk_d3130c9a7f_p_tmp

  def up
    add_concurrent_partitioned_foreign_key(:p_ci_builds, :p_ci_pipelines,
      column: [:partition_id, :commit_id],
      target_column: [:partition_id, :id],
      name: FK_NAME,
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      validate: false
    )
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists partition.identifier, name: FK_NAME, reverse_lock_order: true
      end
    end
  end
end
