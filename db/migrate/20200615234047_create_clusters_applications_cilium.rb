# frozen_string_literal: true

class CreateClustersApplicationsCilium < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :clusters_applications_cilium do |t|
      t.references :cluster, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :status, null: false
      t.text :status_reason # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
end
