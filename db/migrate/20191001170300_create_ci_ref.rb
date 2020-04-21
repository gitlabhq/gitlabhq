# frozen_string_literal: true

class CreateCiRef < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :ci_refs do |t|
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.integer :lock_version, default: 0
      t.integer :last_updated_by_pipeline_id
      t.boolean :tag, default: false, null: false
      t.string :ref, null: false, limit: 255
      t.string :status, null: false, limit: 255
      t.foreign_key :ci_pipelines, column: :last_updated_by_pipeline_id, on_delete: :nullify
      t.index [:project_id, :ref, :tag], unique: true
      t.index [:last_updated_by_pipeline_id]
    end
  end
  # rubocop:enable Migration/PreventStrings
end
