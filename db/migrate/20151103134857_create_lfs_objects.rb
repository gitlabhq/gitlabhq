# rubocop:disable all
class CreateLfsObjects < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :lfs_objects do |t|
      t.string :oid, null: false, unique: true
      t.integer :size, null: false

      t.timestamps null: true
    end
  end
end
