# frozen_string_literal: true

class AddRootNamespacePathToGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  def up
    with_lock_retries do
      add_column :group_secrets_managers, :root_namespace_path, :text
    end

    add_text_limit :group_secrets_managers, :root_namespace_path, 64
  end

  def down
    with_lock_retries do
      remove_column :group_secrets_managers, :root_namespace_path, if_exists: true
    end
  end
end
