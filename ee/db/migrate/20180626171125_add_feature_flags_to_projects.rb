class AddFeatureFlagsToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :operations_feature_flags, id: :bigserial do |t|
      t.integer :project_id, null: false
      t.boolean :active, null: false

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.string :name, null: false
      t.text :description

      t.foreign_key :projects, column: :project_id, on_delete: :cascade

      t.index [:project_id, :name], unique: true
    end

    create_table :operations_feature_flags_clients, id: :bigserial  do |t|
      t.integer :project_id, null: false
      t.string :token, null: false

      t.index [:project_id, :token], unique: true

      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
  end
end
