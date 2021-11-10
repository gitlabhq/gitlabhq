# frozen_string_literal: true

class RemoveIndexForResourceGroup < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_for_resource_group'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end

  def down
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index :ci_builds, [:resource_group_id, :id], where: 'resource_group_id IS NOT NULL', name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end
end
