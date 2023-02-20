# frozen_string_literal: true

class CreateAutomationRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :automation_rules do |t|
      t.references :namespace, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.boolean :issues_events, default: false, null: false
      t.boolean :merge_requests_events, default: false, null: false
      t.boolean :permanently_disabled, default: false, null: false
      t.text :name, null: false, limit: 255
      t.text :rule, null: false, limit: 2048
      t.timestamps_with_timezone null: false

      t.index 'namespace_id, LOWER(name)',
        name: 'index_automation_rules_namespace_id_name',
        unique: true

      t.index [:namespace_id, :permanently_disabled],
        name: 'index_automation_rules_namespace_id_permanently_disabled'
    end
  end

  def down
    drop_table :automation_rules
  end
end
