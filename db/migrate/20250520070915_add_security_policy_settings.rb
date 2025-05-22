# frozen_string_literal: true

class AddSecurityPolicySettings < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_security_policy_settings_on_csp_namespace_id'

  def up
    create_table :security_policy_settings do |t|
      t.bigint :csp_namespace_id, null: true
      t.boolean :singleton, null: false, default: true, comment: 'Always true, used for singleton enforcement'
    end

    add_check_constraint :security_policy_settings, "(singleton IS TRUE)", 'check_singleton'
    add_index :security_policy_settings, :singleton, unique: true
    add_index :security_policy_settings, :csp_namespace_id, name: INDEX_NAME
  end

  def down
    drop_table :security_policy_settings
  end
end
