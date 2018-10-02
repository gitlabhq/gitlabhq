class AddFeatureFlagsToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    create_table :operations_feature_flags do |t|
      t.integer :project_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false

      t.foreign_key :projects, column: :project_id, on_delete: :cascade

      t.index [:project_id, :name], unique: true
    end

    create_table :operations_feature_flags_instances do |t|
      t.integer :project_id, null: false
      t.string :token, null: false

      t.index :token, unique: true

      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
  end

  def down
    drop_table :operations_feature_flags
    drop_table :operations_feature_flags_instances
  end
end
