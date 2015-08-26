class CreateBuilds < ActiveRecord::Migration
  def up
    create_table :builds do |t|
      t.integer :project_id
      t.string :commit_ref
      t.string :status
      t.datetime :finished_at
      t.text :trace
      t.timestamps
    end
  end

  def down
  end
end
