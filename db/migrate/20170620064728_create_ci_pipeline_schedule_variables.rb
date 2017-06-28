class CreateCiPipelineScheduleVariables < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :ci_pipeline_schedule_variables do |t|
      t.string :key, null: false
      t.text :value
      t.text :encrypted_value
      t.string :encrypted_value_salt
      t.string :encrypted_value_iv
      t.integer :pipeline_schedule_id, null: false

      t.timestamps_with_timezone null: true
    end

    add_index :ci_pipeline_schedule_variables,
      [:pipeline_schedule_id, :key],
      name: "index_ci_pipeline_schedule_variables_on_schedule_id_and_key",
      unique: true
  end

  def down
    drop_table :ci_pipeline_schedule_variables
  end
end
