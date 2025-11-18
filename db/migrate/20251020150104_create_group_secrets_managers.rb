# frozen_string_literal: true

class CreateGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    create_table :group_secrets_managers do |t|
      t.timestamps_with_timezone null: false
      t.references :group, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }, unique: true
      t.integer :status, default: 0, null: false, limit: 2
    end
  end
end
