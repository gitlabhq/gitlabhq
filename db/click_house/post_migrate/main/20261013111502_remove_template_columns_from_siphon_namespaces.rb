# frozen_string_literal: true

class RemoveTemplateColumnsFromSiphonNamespaces < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_namespaces
        DROP COLUMN IF EXISTS file_template_project_id,
        DROP COLUMN IF EXISTS custom_project_templates_group_id;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_namespaces
        ADD COLUMN IF NOT EXISTS file_template_project_id Nullable(Int64) AFTER runners_token,
        ADD COLUMN IF NOT EXISTS custom_project_templates_group_id Nullable(Int64) AFTER runners_token_encrypted;
    SQL
  end
end
