# frozen_string_literal: true

class DeleteIndexMembersOnSourceIdAndSourceType < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_members_on_source_id_and_source_type'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :members, name: INDEX_NAME
  end

  def down
    add_concurrent_index :members, %i[source_id source_type], name: INDEX_NAME
  end
end
