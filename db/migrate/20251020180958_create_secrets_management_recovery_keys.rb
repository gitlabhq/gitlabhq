# frozen_string_literal: true

class CreateSecretsManagementRecoveryKeys < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  INDEX_NAME = "idx_secrets_management_recovery_keys_on_active_true"

  def change
    create_table :secrets_management_recovery_keys do |t|
      t.timestamps_with_timezone null: false
      t.boolean :active, null: false, default: false
      t.jsonb :key, null: false

      t.index :active, name: INDEX_NAME, unique: true, where: 'active'
    end
  end
end
