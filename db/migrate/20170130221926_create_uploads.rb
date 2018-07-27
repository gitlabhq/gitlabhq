class CreateUploads < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :uploads do |t|
      t.integer :size, limit: 8, null: false
      t.string :path, null: false
      t.string :checksum, limit: 64
      t.references :model, polymorphic: true
      t.string :uploader, null: false
      t.datetime :created_at, null: false
    end

    add_index :uploads, :path
    add_index :uploads, :checksum
    add_index :uploads, [:model_id, :model_type]
  end
end
