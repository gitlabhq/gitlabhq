class CreateVariables < ActiveRecord::Migration
  def change
    create_table :variables do |t|
      t.integer :project_id, null: false
      t.string :key
      t.text :value
    end

    add_index :variables, :project_id
  end
end