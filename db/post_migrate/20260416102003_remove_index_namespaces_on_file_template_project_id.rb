# frozen_string_literal: true

class RemoveIndexNamespacesOnFileTemplateProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  INDEX_NAME = 'index_namespaces_on_file_template_project_id'

  def up
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end

  def down
    add_concurrent_index :namespaces, :file_template_project_id, name: INDEX_NAME
  end
end
