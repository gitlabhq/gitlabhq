# frozen_string_literal: true

class CreateAiToolRules < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    create_table :ai_tool_rules, if_not_exists: true do |t|
      t.references :namespace,
        null: false,
        index: false,
        foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false
      t.integer :web_access, limit: 2, null: true
      t.integer :local_access, limit: 2, null: true
      t.text :tool_name, null: false, limit: 255
      t.text :tool_source, null: true, limit: 255
      t.jsonb :tool_arguments, null: true

      t.check_constraint \
        "web_access IS NOT NULL OR local_access IS NOT NULL",
        name: "chk_ai_tool_rules_has_permission"

      t.check_constraint \
        "web_access IS NULL OR web_access IN (0, 1, 2)",
        name: "chk_ai_tool_rules_web_access_enum"

      t.check_constraint \
        "local_access IS NULL OR local_access IN (0, 1, 2)",
        name: "chk_ai_tool_rules_local_access_enum"

      t.index [:namespace_id, :tool_name],
        unique: true,
        name: "idx_ai_tool_rules_ns_tool_unique"
    end
  end

  def down
    drop_table :ai_tool_rules
  end
end
