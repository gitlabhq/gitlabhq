# frozen_string_literal: true

class IndexNamespaceDetailsOnCreatorId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_namespace_details_on_creator_id'

  def up
    add_concurrent_index :namespace_details, :creator_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespace_details, INDEX_NAME
  end
end
