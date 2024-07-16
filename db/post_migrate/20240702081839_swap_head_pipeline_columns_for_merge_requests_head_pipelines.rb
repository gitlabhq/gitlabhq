# frozen_string_literal: true

class SwapHeadPipelineColumnsForMergeRequestsHeadPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::Swapping

  milestone '17.2'
  disable_ddl_transaction!

  TABLE_NAME = :merge_requests
  INDEX_NAME = :index_merge_requests_on_head_pipeline_id
  BIGINT_INDEX_NAME = :index_merge_requests_on_head_pipeline_id_bigint
  COLUMN_NAME = :head_pipeline_id
  BIGINT_COLUMN_NAME = :head_pipeline_id_convert_to_bigint
  TRIGGER_FUNCTIONS = [:trigger_fb587b1ae7ad, :insert_into_loose_foreign_keys_deleted_records]

  def up
    add_concurrent_index TABLE_NAME, BIGINT_COLUMN_NAME, name: BIGINT_INDEX_NAME

    swap
  end

  def down
    add_concurrent_index TABLE_NAME, BIGINT_COLUMN_NAME, name: BIGINT_INDEX_NAME

    swap
  end

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      # Not locking ci_pipelines as it's a LFK column
      lock_tables(TABLE_NAME)

      swap_columns(TABLE_NAME, COLUMN_NAME, BIGINT_COLUMN_NAME)

      TRIGGER_FUNCTIONS.each do |trigger|
        reset_trigger_function(trigger)
      end

      execute "DROP INDEX #{INDEX_NAME}"
      rename_index TABLE_NAME, BIGINT_INDEX_NAME, INDEX_NAME
    end
  end
end
