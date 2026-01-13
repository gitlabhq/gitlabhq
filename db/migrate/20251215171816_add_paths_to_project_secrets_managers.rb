# frozen_string_literal: true

class AddPathsToProjectSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  def up
    add_column :project_secrets_managers, :namespace_path, :text
    add_text_limit :project_secrets_managers, :namespace_path, 64

    add_column :project_secrets_managers, :project_path, :text
    add_text_limit :project_secrets_managers, :project_path, 64
  end

  def down
    remove_column :project_secrets_managers, :project_path, if_exists: true
    remove_column :project_secrets_managers, :namespace_path, if_exists: true
  end
end
