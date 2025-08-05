# frozen_string_literal: true

class CreateProjectToSecurityAttributes < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  PROJECT_SECURITY_ATTRIBUTES_TRAVERSAL_INDEX = 'index_project_security_attributes_traversal_ids'
  PROJECT_SECURITY_ATTRIBUTES_PROJECT_ID_UNIQUE = 'index_project_security_attributes_project_id_unique'

  def change
    create_table :project_to_security_attributes do |t|
      t.bigint :project_id, null: false
      t.references :security_attribute, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.timestamps_with_timezone null: false
      t.bigint :traversal_ids, array: true, default: [], null: false

      t.index :traversal_ids, name: PROJECT_SECURITY_ATTRIBUTES_TRAVERSAL_INDEX
      t.index [:project_id, :security_attribute_id], unique: true, name: PROJECT_SECURITY_ATTRIBUTES_PROJECT_ID_UNIQUE
    end
  end
end
