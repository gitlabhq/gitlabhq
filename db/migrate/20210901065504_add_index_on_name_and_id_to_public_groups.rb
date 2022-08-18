# frozen_string_literal: true

class AddIndexOnNameAndIdToPublicGroups < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_namespaces_public_groups_name_id'
  PUBLIC_VISIBILITY_LEVEL = 20

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, [:name, :id],
                         name: INDEX_NAME,
                         where: "type = 'Group' AND visibility_level = #{PUBLIC_VISIBILITY_LEVEL}"
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end
