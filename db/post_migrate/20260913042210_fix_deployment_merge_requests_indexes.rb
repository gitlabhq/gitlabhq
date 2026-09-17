# frozen_string_literal: true

class FixDeploymentMergeRequestsIndexes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = :deployment_merge_requests
  COLUMN_NAME = :deployment_id
  INDEX_NAME = :tmp_idx_deployment_merge_requests_on_deployment_id

  # rubocop:disable Migration/PreventIndexCreation -- temporary index required by bigint migration
  def up
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN_NAME))

    if columns_already_swapped?
      add_concurrent_index(TABLE_NAME, convert_to_bigint_column(COLUMN_NAME), name: INDEX_NAME)
    else
      add_concurrent_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
    end
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    return unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN_NAME))

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  private

  def columns_already_swapped?
    column_for(TABLE_NAME, convert_to_bigint_column(COLUMN_NAME)).sql_type == 'integer'
  end
end
