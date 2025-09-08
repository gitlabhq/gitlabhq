# frozen_string_literal: true

class AddLabelLinksNamespaceIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_label_links_on_namespace_id'

  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_index :label_links, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :label_links, :namespace_id, name: INDEX_NAME
  end
end
