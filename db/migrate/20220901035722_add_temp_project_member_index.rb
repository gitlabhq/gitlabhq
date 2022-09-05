# frozen_string_literal: true

class AddTempProjectMemberIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = :members
  INDEX_NAME = 'index_project_members_on_id_temp'

  def up
    add_concurrent_index TABLE_NAME, :id, name: INDEX_NAME, where: "source_type = 'Project'"
  end

  def down
    remove_concurrent_index TABLE_NAME, :id, name: INDEX_NAME
  end
end
