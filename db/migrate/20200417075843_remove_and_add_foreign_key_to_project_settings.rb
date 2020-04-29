# frozen_string_literal: true

class RemoveAndAddForeignKeyToProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_project_settings_push_rule_id'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_settings, :push_rules, column: :push_rule_id, name: CONSTRAINT_NAME, on_delete: :nullify
    remove_foreign_key_if_exists :project_settings, column: :push_rule_id, on_delete: :cascade
  end

  def down
    add_concurrent_foreign_key :project_settings, :push_rules, column: :push_rule_id, on_delete: :cascade
    remove_foreign_key_if_exists :project_settings, column: :push_rule_id, name: CONSTRAINT_NAME, on_delete: :nullify
  end
end
