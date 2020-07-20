# frozen_string_literal: true

class RecreateCiRef < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  UNKNOWN_STATUS = 0

  def up
    with_lock_retries do
      # rubocop:disable Migration/DropTable
      drop_table :ci_refs
      # rubocop:enable Migration/DropTable

      create_table :ci_refs do |t|
        t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }, type: :bigint
        t.integer :lock_version, null: false, default: 0
        t.integer :status, null: false, limit: 2, default: UNKNOWN_STATUS
        t.text :ref_path, null: false # rubocop: disable Migration/AddLimitToTextColumns
        t.index [:project_id, :ref_path], unique: true
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :ci_refs

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
  end
end
