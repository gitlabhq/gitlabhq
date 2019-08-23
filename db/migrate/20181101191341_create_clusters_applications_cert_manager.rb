# frozen_string_literal: true

class CreateClustersApplicationsCertManager < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :clusters_applications_cert_managers do |t|
      t.references :cluster, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.integer :status, null: false
      t.string :version, null: false
      t.string :email, null: false
      t.timestamps_with_timezone null: false
      t.text :status_reason
      t.index :cluster_id, unique: true
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
