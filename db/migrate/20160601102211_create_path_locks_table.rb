class CreatePathLocksTable < ActiveRecord::Migration
  def change
    create_table :path_locks do |t|
      t.string :path, null: false, index: true
      t.references :project, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
