# frozen_string_literal: true

class RemoveOldExternalDiffMigrationIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(
      :merge_request_diffs,
      'index_merge_request_diffs_on_merge_request_id_and_id_partial'
    )
  end

  def down
    add_concurrent_index(
      :merge_request_diffs,
      [:merge_request_id, :id],
      where: 'NOT stored_externally OR stored_externally IS NULL',
      name: 'index_merge_request_diffs_on_merge_request_id_and_id_partial'
    )
  end
end
