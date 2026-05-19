# frozen_string_literal: true

class RemoveIndexNamespacesOnCustomProjectTemplatesGroupIdAndType < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  INDEX_NAME = 'index_namespaces_on_custom_project_templates_group_id_and_type'

  def up
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end

  def down
    add_concurrent_index :namespaces, [:custom_project_templates_group_id, :type],
      name: INDEX_NAME, where: 'custom_project_templates_group_id IS NOT NULL'
  end
end
