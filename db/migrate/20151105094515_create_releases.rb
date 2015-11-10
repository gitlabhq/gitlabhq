class CreateReleases < ActiveRecord::Migration
  def change
    create_table :releases do |t|
      t.string :tag
      t.text :description
      t.integer :project_id

      t.timestamps
    end

    add_index :releases, :project_id
    add_index :releases, [:project_id, :tag]
  end
end
