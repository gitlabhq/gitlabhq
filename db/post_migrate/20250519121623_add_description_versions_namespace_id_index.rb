# frozen_string_literal: true

class AddDescriptionVersionsNamespaceIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_description_versions_on_namespace_id'

  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_index :description_versions, :namespace_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding keys are an exception
  end

  def down
    remove_concurrent_index_by_name :description_versions, name: INDEX_NAME
  end
end
