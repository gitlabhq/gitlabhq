class CreateProjectCustomAttributes < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :project_custom_attributes do |t|
      t.timestamps_with_timezone null: false
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.string :key, null: false
      t.string :value, null: false

      t.index [:project_id, :key], unique: true
      t.index [:key, :value]
    end
  end
end
