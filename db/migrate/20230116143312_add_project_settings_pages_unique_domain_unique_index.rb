# frozen_string_literal: true

class AddProjectSettingsPagesUniqueDomainUniqueIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_index :project_settings,
      :pages_unique_domain,
      unique: true,
      where: 'pages_unique_domain IS NOT NULL',
      name: 'unique_index_for_project_pages_unique_domain'
  end

  def down
    remove_concurrent_index :project_settings,
      :pages_unique_domain,
      unique: true,
      name: 'unique_index_for_project_pages_unique_domain'
  end
end
