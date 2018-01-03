class CreateGroupVariablesTable < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :ci_group_variables do |t|
      t.string :key, null: false
      t.text :value
      t.text :encrypted_value
      t.string :encrypted_value_salt
      t.string :encrypted_value_iv
      t.integer :group_id, null: false
      t.boolean :protected, default: false, null: false

      t.timestamps_with_timezone null: false
    end

    add_index :ci_group_variables, [:group_id, :key], unique: true
  end

  def down
    drop_table :ci_group_variables
  end
end
