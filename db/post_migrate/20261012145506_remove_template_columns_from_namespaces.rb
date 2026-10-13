# frozen_string_literal: true

class RemoveTemplateColumnsFromNamespaces < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!
  milestone '19.6'

  def up
    with_lock_retries do
      remove_column :namespaces, :file_template_project_id, if_exists: true
      remove_column :namespaces, :custom_project_templates_group_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :namespaces, :file_template_project_id, :bigint, if_not_exists: true
      add_column :namespaces, :custom_project_templates_group_id, :bigint, if_not_exists: true
    end
  end
end
