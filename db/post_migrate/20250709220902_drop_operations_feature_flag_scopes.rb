# frozen_string_literal: true

class DropOperationsFeatureFlagScopes < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    drop_table :operations_feature_flag_scopes
  end

  def down
    create_table :operations_feature_flag_scopes do |t|
      t.bigint :feature_flag_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :active, null: false
      t.string :environment_scope, null: false, default: '*'
      t.jsonb :strategies, null: false, default: [{ name: "default", parameters: {} }]

      t.index [:feature_flag_id, :environment_scope], unique: true,
        name: 'index_feature_flag_scopes_on_flag_id_and_environment_scope'
    end
  end
end
