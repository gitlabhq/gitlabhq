# frozen_string_literal: true

class AddPushRulesForeignKeyToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_index :application_settings, :push_rule_id, unique: true
    add_concurrent_foreign_key :application_settings, :push_rules, column: :push_rule_id, on_delete: :nullify
  end

  def down
    remove_concurrent_index :application_settings, :push_rule_id
    remove_foreign_key_if_exists :application_settings, column: :push_rule_id
  end
end
