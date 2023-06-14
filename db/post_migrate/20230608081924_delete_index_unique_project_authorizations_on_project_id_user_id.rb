# frozen_string_literal: true

class DeleteIndexUniqueProjectAuthorizationsOnProjectIdUserId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_unique_project_authorizations_on_project_id_user_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :project_authorizations, name: INDEX_NAME
  end

  def down
    add_concurrent_index :project_authorizations, %i[project_id user_id], name: INDEX_NAME
  end
end
