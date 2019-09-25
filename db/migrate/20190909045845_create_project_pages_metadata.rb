# frozen_string_literal: true

class CreateProjectPagesMetadata < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :project_pages_metadata, id: false do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.boolean :deployed, null: false, default: false

      t.index :project_id, name: 'index_project_pages_metadata_on_project_id_and_deployed_is_true', where: "deployed = TRUE"
    end
  end
end
