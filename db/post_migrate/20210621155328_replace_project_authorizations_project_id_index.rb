# frozen_string_literal: true

class ReplaceProjectAuthorizationsProjectIdIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_project_authorizations_on_project_id'
  NEW_INDEX_NAME = 'index_project_authorizations_on_project_id_user_id'

  def up
    add_concurrent_index(:project_authorizations, [:project_id, :user_id], name: NEW_INDEX_NAME)
    remove_concurrent_index_by_name(:project_authorizations, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:project_authorizations, :project_id, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(:project_authorizations, NEW_INDEX_NAME)
  end
end
