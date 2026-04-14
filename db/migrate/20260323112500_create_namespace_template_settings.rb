# frozen_string_literal: true

class CreateNamespaceTemplateSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    create_table :namespace_template_settings, id: false do |t|
      t.references :namespace, primary_key: true, default: nil, type: :bigint,
        index: false, foreign_key: { on_delete: :cascade }
      t.bigint :file_template_project_id
      t.bigint :custom_project_templates_group_id

      t.timestamps_with_timezone null: false

      t.index :file_template_project_id,
        name: 'index_namespace_template_settings_on_file_template_project_id'
      t.index :custom_project_templates_group_id,
        name: 'index_ns_template_settings_on_custom_project_templates_group_id',
        where: 'custom_project_templates_group_id IS NOT NULL'
    end
  end

  def down
    drop_table :namespace_template_settings
  end
end
