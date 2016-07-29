class AddApproversTable < ActiveRecord::Migration
  def change
    create_table :approvers do |t|
      t.integer :target_id, null: false
      t.string :target_type
      t.integer :user_id, null: false

      t.timestamps

      t.index [:target_id, :target_type]
      t.index :user_id
    end
  end
end
