# frozen_string_literal: true

class CreateSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  INDEX_NAME = "index_security_policies_on_unique_config_type_policy_index"

  def change
    create_table :security_policies do |t|
      t.references :security_orchestration_policy_configuration,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      t.timestamps_with_timezone null: false
      t.integer :policy_index, limit: 2, null: false
      t.integer :type, limit: 2, null: false
      t.boolean :enabled, default: true, null: false
      t.text :name, limit: 255, null: false
      t.text :description, limit: 255
      t.text :checksum, limit: 255, null: false
      t.jsonb :scope, default: {}, null: false
      t.jsonb :actions, default: [], null: false
      t.jsonb :approval_settings, default: {}, null: false
    end

    add_index(
      :security_policies,
      %i[security_orchestration_policy_configuration_id type policy_index],
      unique: true,
      name: INDEX_NAME)
  end
end
