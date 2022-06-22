# frozen_string_literal: true

class DropIndexOnProjectsOnRunnersTokenEncrypted < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_runners_token_encrypted'

  def up
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects,
                         :runners_token_encrypted,
                         name: INDEX_NAME
  end
end
