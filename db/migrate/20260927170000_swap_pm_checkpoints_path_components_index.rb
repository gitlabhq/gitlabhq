# frozen_string_literal: true

class SwapPmCheckpointsPathComponentsIndex < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = :pm_checkpoints
  COLUMNS = %i[purl_type data_type version_format].freeze
  OLD_INDEX_NAME = 'pm_checkpoints_path_components'
  NEW_INDEX_NAME = 'index_pm_checkpoints_on_path_components'

  def up
    add_concurrent_index TABLE_NAME, COLUMNS, unique: true, nulls_not_distinct: true, name: NEW_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, COLUMNS, unique: true, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end
