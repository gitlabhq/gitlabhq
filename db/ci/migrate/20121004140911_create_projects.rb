class CreateProjects < ActiveRecord::Migration
  def up
    create_table :projects do |t|
      t.string :name, null: false
      t.string :path, null: false
      t.integer :timeout, null: false, default: 1800
      t.text :scripts, null: false
      t.timestamps
    end
  end

  def down
  end
end
