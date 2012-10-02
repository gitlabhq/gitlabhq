class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.integer :owner_id, null: false

      t.timestamps
    end
  end
end
