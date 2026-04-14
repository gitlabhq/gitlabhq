# frozen_string_literal: true

class AddFkNamespaceTemplateSettingsCustomProjectTemplatesGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespace_template_settings, :namespaces,
      column: :custom_project_templates_group_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :namespace_template_settings, :namespaces,
        column: :custom_project_templates_group_id
    end
  end
end
