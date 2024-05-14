# frozen_string_literal: true

class SwapMergeTrainsPipelineIdConvertToBigint < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::Swapping
  milestone '17.0'
  disable_ddl_transaction!

  TABLE_NAME = :merge_trains
  COLUMN_NAME = :pipeline_id
  BIGINT_COLUMN_NAME = :pipeline_id_convert_to_bigint
  INDEX_NAME = :index_merge_trains_on_pipeline_id
  BIGINT_INDEX_NAME = :index_merge_trains_on_pipeline_id_bigint

  def up
    swap
  end

  def down
    # To swap back to original indexes
    add_concurrent_index TABLE_NAME, BIGINT_COLUMN_NAME, name: BIGINT_INDEX_NAME

    swap

    # Add previously deleted indexes
    add_concurrent_index TABLE_NAME, BIGINT_COLUMN_NAME, name: BIGINT_INDEX_NAME
  end

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      # Not locking ci_pipelines as it's an LFK column
      lock_tables(TABLE_NAME)

      swap_columns(TABLE_NAME, COLUMN_NAME, BIGINT_COLUMN_NAME)

      reset_trigger_function(:trigger_3857ca5ea4af)

      # No defaults to swap as the column is not a PK one

      execute "DROP INDEX #{INDEX_NAME}"
      rename_index TABLE_NAME, BIGINT_INDEX_NAME, INDEX_NAME
    end
  end
end
