# frozen_string_literal: true

class SwapPackagesBuildInfosPipelineIdConvertToBigint < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::Swapping
  milestone '17.0'
  disable_ddl_transaction!

  TABLE_NAME = :packages_build_infos
  COLUMN_NAME = :pipeline_id
  BIGINT_COLUMN_NAME = :pipeline_id_convert_to_bigint
  INDEX_NAME = :index_packages_build_infos_on_pipeline_id
  COMPOSITE_INDEX_NAME = :index_packages_build_infos_package_id_pipeline_id_id
  BIGINT_INDEX_NAME = :index_packages_build_infos_on_pipeline_id_bigint
  COMPOSITE_BIGINT_INDEX_NAME = :index_packages_build_infos_package_id_pipeline_id_bigint_id
  COMPOSITE_INDEX_COLUMNS = [:package_id, :pipeline_id_convert_to_bigint, :id]

  def up
    swap
  end

  def down
    # To swap back to original indexes
    add_concurrent_index TABLE_NAME, BIGINT_COLUMN_NAME, name: BIGINT_INDEX_NAME
    add_concurrent_index TABLE_NAME, COMPOSITE_INDEX_COLUMNS, name: COMPOSITE_BIGINT_INDEX_NAME

    swap

    # Add previously deleted indexes
    add_concurrent_index TABLE_NAME, BIGINT_COLUMN_NAME, name: BIGINT_INDEX_NAME
    add_concurrent_index TABLE_NAME, COMPOSITE_INDEX_COLUMNS, name: COMPOSITE_BIGINT_INDEX_NAME
  end

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      # Not locking ci_pipelines as it's an LFK column
      lock_tables(TABLE_NAME)

      swap_columns(TABLE_NAME, COLUMN_NAME, BIGINT_COLUMN_NAME)

      reset_trigger_function(:trigger_388e93f88fdd)

      # No defaults to swap as the column is not a PK one

      execute "DROP INDEX #{INDEX_NAME}"
      rename_index TABLE_NAME, BIGINT_INDEX_NAME, INDEX_NAME

      execute "DROP INDEX #{COMPOSITE_INDEX_NAME}"
      rename_index TABLE_NAME, COMPOSITE_BIGINT_INDEX_NAME, COMPOSITE_INDEX_NAME
    end
  end
end
