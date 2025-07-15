# frozen_string_literal: true

class RemoveCiPipelinesConfigPipelineForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  FK_NAME = :fk_rails_906c9a2533_p

  disable_ddl_transaction!

  milestone '18.3'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_pipelines_config, :p_ci_pipelines,
        name: FK_NAME, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(
      :p_ci_pipelines_config, :p_ci_pipelines,
      name: FK_NAME,
      column: [:partition_id, :pipeline_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end
end
