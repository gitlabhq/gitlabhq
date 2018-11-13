# frozen_string_literal: true

class CreateClustersApplicationsCertManager < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :clusters_applications_cert_managers do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }
      t.integer :status, null: false
      t.string :version, null: false
      t.string :email, null:false
      t.timestamps_with_timezone null: false
      t.text :status_reason
    end
  end
end
