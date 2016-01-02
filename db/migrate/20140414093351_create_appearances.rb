class CreateAppearances < ActiveRecord::Migration
  def change
    create_table :appearances do |t|
      t.string :title
      t.text :description
      t.string :logo
      t.integer :updated_by

      t.timestamps
    end
  end
end
