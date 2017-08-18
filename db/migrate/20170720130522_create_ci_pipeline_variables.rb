class CreateCiPipelineVariables < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :ci_pipeline_variables do |t|
      t.string :key, null: false
      t.text :value
      t.text :encrypted_value
      t.string :encrypted_value_salt
      t.string :encrypted_value_iv
      t.integer :pipeline_id, null: false
    end

    add_index :ci_pipeline_variables, [:pipeline_id, :key], unique: true
  end

  def down
    drop_table :ci_pipeline_variables
  end
end
