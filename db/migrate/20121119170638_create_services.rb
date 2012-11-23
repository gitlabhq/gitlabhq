class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :type
      t.string :title
      t.string :token
      t.integer :project_id, null: false

      t.timestamps
    end
  end
end
