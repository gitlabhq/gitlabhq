# frozen_string_literal: true

class AddOrganizationGroupsProjectsSort < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :user_preferences, :organization_groups_projects_sort, :text, if_not_exists: true
    end

    add_text_limit :user_preferences, :organization_groups_projects_sort, 64
  end

  def down
    with_lock_retries do
      remove_column :user_preferences, :organization_groups_projects_sort, if_exists: true
    end
  end
end
