# frozen_string_literal: true

class AddIndexToMembersOnSourceAndTypeAndAccessLevel < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_members_on_source_and_type_and_access_level'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, %i[source_id source_type type access_level], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
