# frozen_string_literal: true

class IndexIssuableSlasOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issuable_slas_on_namespace_id'

  def up
    add_concurrent_index :issuable_slas, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issuable_slas, INDEX_NAME
  end
end
