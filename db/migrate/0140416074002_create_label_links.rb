class CreateLabelLinks < ActiveRecord::Migration
  def change
    create_table :label_links do |t|
      t.integer :label_id
      t.integer :target_id
      t.string :target_type

      t.timestamps
    end
  end
end
