class CreateTrigger < ActiveRecord::Migration
  def up
    create_table :triggers do |t|
      t.string :token, null: true
      t.integer :project_id, null: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :triggers, :deleted_at
  end
end
