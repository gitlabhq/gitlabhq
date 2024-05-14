# frozen_string_literal: true

class CreateIndexesForPackagesBuildInfosPipelineIdConvertToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  TABLE_NAME = :packages_build_infos
  COLUMN_NAME = :pipeline_id_convert_to_bigint
  INDEX_NAME = :index_packages_build_infos_on_pipeline_id_bigint
  COMPOSITE_INDEX_NAME = :index_packages_build_infos_package_id_pipeline_id_bigint_id
  COMPOSITE_INDEX_COLUMNS = [:package_id, :pipeline_id_convert_to_bigint, :id]

  def up
    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
    add_concurrent_index TABLE_NAME, COMPOSITE_INDEX_COLUMNS, name: COMPOSITE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, name: COMPOSITE_INDEX_NAME
  end
end
