# frozen_string_literal: true

class AddIndexTimelogsOnNamespaceId < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_timelogs_on_namespace_id'

  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_index :timelogs, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :timelogs, :namespace_id, name: INDEX_NAME
  end
end
