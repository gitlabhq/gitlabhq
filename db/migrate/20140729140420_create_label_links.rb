# rubocop:disable all
class CreateLabelLinks < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :label_links do |t|
      t.integer :label_id
      t.integer :target_id
      t.string :target_type

      t.timestamps null: true
    end
  end
end
