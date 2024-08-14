# frozen_string_literal: true

class CreateProjectSecretsManagers < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    create_table :project_secrets_managers do |t|
      t.timestamps_with_timezone null: false
      t.references :project, index: { unique: true }, foreign_key: { on_delete: :cascade }, null: false
      t.integer :status, default: 0, null: false, limit: 2
    end
  end
end
