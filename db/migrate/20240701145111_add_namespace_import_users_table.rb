# frozen_string_literal: true

class AddNamespaceImportUsersTable < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    create_table :namespace_import_users do |t|
      t.bigint :user_id, null: false
      t.bigint :namespace_id, null: false

      t.index :namespace_id, unique: true, name: :index_namespace_import_users_on_namespace_id
      t.index :user_id, unique: true, name: :index_namespace_import_users_on_user_id
    end
  end

  def down
    drop_table :namespace_import_users
  end
end
