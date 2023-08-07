# frozen_string_literal: true

class AddUniqueIndexProjectAuthorizationsOnUniqueProjectUser < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_unique_project_authorizations_on_unique_project_user'

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_authorizations,
      %i[project_id user_id],
      unique: true,
      where: "is_unique",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_authorizations, INDEX_NAME
  end
end
