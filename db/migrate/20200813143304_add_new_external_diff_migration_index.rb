# frozen_string_literal: true

class AddNewExternalDiffMigrationIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_merge_request_diffs_by_id_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :merge_request_diffs,
      :id,
      name: INDEX_NAME,
      where: 'files_count > 0 AND ((NOT stored_externally) OR (stored_externally IS NULL))'
    )
  end

  def down
    remove_concurrent_index_by_name(:merge_request_diffs, INDEX_NAME)
  end
end
