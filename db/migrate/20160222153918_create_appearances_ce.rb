class CreateAppearancesCe < ActiveRecord::Migration
  def change
    unless table_exists?(:appearances)
      create_table :appearances do |t|
        t.string :title
        t.text :description
        t.string :header_logo
        t.string :logo

        t.timestamps null: false
      end
    end
  end
end
