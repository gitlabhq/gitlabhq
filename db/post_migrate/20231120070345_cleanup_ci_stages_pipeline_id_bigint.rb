# frozen_string_literal: true

class CleanupCiStagesPipelineIdBigint < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone "16.7"

  TABLE = :ci_stages
  REFERENCING_TABLE = :ci_pipelines
  COLUMN = :pipeline_id
  OLD_COLUMN = :pipeline_id_convert_to_bigint
  INDEXES = {
    'index_ci_stages_on_pipeline_id_convert_to_bigint_and_name' => [
      [:pipeline_id_convert_to_bigint, :name], { unique: true }
    ],
    'index_ci_stages_on_pipeline_id_convert_to_bigint' => [
      [:pipeline_id_convert_to_bigint], {}
    ],
    'index_ci_stages_on_pipeline_id_convert_to_bigint_and_id' => [
      [:pipeline_id_convert_to_bigint, :id], { where: 'status = ANY (ARRAY[0, 1, 2, 8, 9, 10])' }
    ],
    'index_ci_stages_on_pipeline_id_convert_to_bigint_and_position' => [
      [:pipeline_id_convert_to_bigint, :position], {}
    ]
  }
  OLD_FK_NAME = :fk_c5ddde695f

  def up
    return unless can_execute_on?(:ci_pipelines, :ci_stages)

    with_lock_retries(raise_on_exhaustion: true) do
      lock_tables(REFERENCING_TABLE, TABLE)
      cleanup_conversion_of_integer_to_bigint(TABLE, [COLUMN])
    end
  end

  def down
    return unless can_execute_on?(:ci_pipelines, :ci_stages)

    restore_conversion_of_integer_to_bigint(TABLE, [COLUMN])

    INDEXES.each do |index_name, (columns, options)|
      add_concurrent_index(TABLE, columns, name: index_name, **options)
    end

    add_concurrent_foreign_key(
      TABLE, REFERENCING_TABLE,
      column: OLD_COLUMN, name: OLD_FK_NAME,
      on_delete: :cascade, validate: true, reverse_lock_order: true
    )
  end
end
