# frozen_string_literal: true

class CreateLabelLinksNamespaceIdAndIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_label_links_on_namespace_id_label_id_and_id'

  disable_ddl_transaction!
  milestone '18.11'

  def up
    add_concurrent_index :label_links, [:namespace_id, :label_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :label_links, [:namespace_id, :label_id, :id], name: INDEX_NAME
  end
end
