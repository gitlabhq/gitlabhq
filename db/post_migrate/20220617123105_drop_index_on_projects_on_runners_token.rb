# frozen_string_literal: true

class DropIndexOnProjectsOnRunnersToken < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_runners_token'

  def up
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects,
                         :runners_token,
                         name: INDEX_NAME
  end
end
