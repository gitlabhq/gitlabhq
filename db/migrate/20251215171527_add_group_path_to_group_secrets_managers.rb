# frozen_string_literal: true

class AddGroupPathToGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  def up
    add_column :group_secrets_managers, :group_path, :text
    add_text_limit :group_secrets_managers, :group_path, 64
  end

  def down
    remove_column :group_secrets_managers, :group_path, if_exists: true
  end
end
