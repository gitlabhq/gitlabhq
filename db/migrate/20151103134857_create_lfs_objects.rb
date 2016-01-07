class CreateLfsObjects < ActiveRecord::Migration
  def change
    create_table :lfs_objects do |t|
      t.string :oid, null: false, unique: true
      t.integer :size, null: false

      t.timestamps
    end
  end
end
