# frozen_string_literal: true

class CreateClustersApplicationsCrossplane < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :clusters_applications_crossplane do |t|
      t.timestamps_with_timezone null: false
      t.references :cluster, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.integer :status, null: false
      t.string :version, null: false, limit: 255
      t.string :stack, null: false, limit: 255
      t.text :status_reason # rubocop:disable Migration/AddLimitToTextColumns
      t.index :cluster_id, unique: true
    end
  end
  # rubocop:enable Migration/PreventStrings
end
