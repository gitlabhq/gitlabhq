# frozen_string_literal: true

class DropClustersApplicationsElasticStacksTable < Gitlab::Database::Migration[2.0]
  def up
    drop_table :clusters_applications_elastic_stacks
  end

  def down
    create_table :clusters_applications_elastic_stacks do |t|
      t.timestamps_with_timezone null: false
      t.references :cluster, type: :bigint, null: false, index: { unique: true }
      t.integer :status, null: false
      t.string :version, null: false, limit: 255
      t.text :status_reason
    end
  end
end
