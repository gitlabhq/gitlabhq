class CleanupStagesPositionMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TMP_INDEX_NAME = 'tmp_id_stage_position_partial_null_index'.freeze

  disable_ddl_transaction!

  class Stages < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_stages'
  end

  def up
    disable_statement_timeout do
      Gitlab::BackgroundMigration.steal('MigrateStageIndex')

      unless index_exists_by_name?(:ci_stages, TMP_INDEX_NAME)
        add_concurrent_index(:ci_stages, :id, where: 'position IS NULL', name: TMP_INDEX_NAME)
      end

      migratable = <<~SQL
        position IS NULL AND EXISTS (
          SELECT 1 FROM ci_builds WHERE stage_id = ci_stages.id AND stage_idx IS NOT NULL
        )
      SQL

      Stages.where(migratable).each_batch(of: 1000) do |batch|
        batch.pluck(:id).each do |stage|
          Gitlab::BackgroundMigration::MigrateStageIndex.new.perform(stage, stage)
        end
      end

      remove_concurrent_index_by_name(:ci_stages, TMP_INDEX_NAME)
    end
  end

  def down
    if index_exists_by_name?(:ci_stages, TMP_INDEX_NAME)
      disable_statement_timeout do
        remove_concurrent_index_by_name(:ci_stages, TMP_INDEX_NAME)
      end
    end
  end
end
