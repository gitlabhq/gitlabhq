# frozen_string_literal: true

class DropUserIdAndSourceIdAndSourceTypeIndexFromMembers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_members_on_user_id_source_id_source_type'

  def up
    remove_concurrent_index_by_name :members, name: INDEX_NAME
  end

  def down
    add_concurrent_index :members, [:user_id, :source_id, :source_type], name: INDEX_NAME
  end
end
