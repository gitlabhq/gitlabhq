# frozen_string_literal: true

class AddIndexToProjectAuthorizationsOnProjectUserAccessLevel < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_project_authorizations_on_project_user_access_level'

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_authorizations, %i[project_id user_id access_level], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :project_authorizations, INDEX_NAME
  end
end
