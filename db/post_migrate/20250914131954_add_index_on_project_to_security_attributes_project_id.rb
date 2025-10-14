# frozen_string_literal: true

class AddIndexOnProjectToSecurityAttributesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  INDEX_NAME = 'index_project_to_security_attributes_on_project_id_and_id'

  def up
    add_concurrent_index :project_to_security_attributes, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_to_security_attributes, INDEX_NAME
  end
end
