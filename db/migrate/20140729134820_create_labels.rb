# rubocop:disable all
class CreateLabels < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :labels do |t|
      t.string :title
      t.string :color
      t.integer :project_id

      t.timestamps null: true
    end
  end
end
