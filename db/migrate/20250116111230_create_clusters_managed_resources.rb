# frozen_string_literal: true

class CreateClustersManagedResources < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :clusters_managed_resources do |t|
      t.references :build, index: { unique: true }, null: false
      t.references :project, null: false
      t.references :environment, null: false
      t.references :cluster_agent, null: false
      t.timestamps_with_timezone null: false
      t.integer :status, default: 0, limit: 2, null: false
      t.text :template_name, limit: 1024
    end
  end
end
