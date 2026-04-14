# frozen_string_literal: true

class AddIndexNamespaceTemplateSettingsDuoTemplateProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespace_template_settings, :duo_template_project_id,
      name: 'index_ns_template_settings_on_duo_template_project_id',
      where: 'duo_template_project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :namespace_template_settings,
      'index_ns_template_settings_on_duo_template_project_id'
  end
end
