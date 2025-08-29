# frozen_string_literal: true

class RemoveTmpIndexForNullMemberNamespaceId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  INDEX_NAME = 'tmp_index_for_null_member_namespace_id'

  def up
    remove_concurrent_index_by_name :members, name: INDEX_NAME
  end

  def down
    add_concurrent_index :members, :member_namespace_id, name: INDEX_NAME, where: "member_namespace_id IS NULL"
  end
end
