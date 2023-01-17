# frozen_string_literal: true

class AddIndexEnvironmentsOnProjectIdAndId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_on_project_id_and_id'

  def up
    add_concurrent_index :environments, %i[project_id id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end
end
