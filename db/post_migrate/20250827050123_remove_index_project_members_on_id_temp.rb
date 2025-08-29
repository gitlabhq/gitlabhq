# frozen_string_literal: true

class RemoveIndexProjectMembersOnIdTemp < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  INDEX_NAME = 'index_project_members_on_id_temp'

  def up
    remove_concurrent_index_by_name :members, name: INDEX_NAME
  end

  def down
    add_concurrent_index :members, :id, name: INDEX_NAME, where: "source_type = 'Project'"
  end
end
