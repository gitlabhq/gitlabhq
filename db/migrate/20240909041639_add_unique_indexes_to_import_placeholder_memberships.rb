# frozen_string_literal: true

class AddUniqueIndexesToImportPlaceholderMemberships < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  SOURCE_USER_INDEX_NAME = 'index_import_placeholder_memberships_on_source_user_id'

  GROUP_INDEX_NAME = 'idx_import_placeholder_memberships_on_source_user_group_id'
  PROJECT_INDEX_NAME = 'idx_import_placeholder_memberships_on_source_user_project_id'

  def up
    remove_concurrent_index_by_name :import_placeholder_memberships, SOURCE_USER_INDEX_NAME

    add_concurrent_index :import_placeholder_memberships, [:source_user_id, :group_id],
      name: GROUP_INDEX_NAME,
      unique: true
    add_concurrent_index :import_placeholder_memberships, [:source_user_id, :project_id],
      name: PROJECT_INDEX_NAME,
      unique: true
  end

  def down
    add_concurrent_index :import_placeholder_memberships, :source_user_id, name: SOURCE_USER_INDEX_NAME

    remove_concurrent_index_by_name :import_placeholder_memberships, PROJECT_INDEX_NAME
    remove_concurrent_index_by_name :import_placeholder_memberships, GROUP_INDEX_NAME
  end
end
