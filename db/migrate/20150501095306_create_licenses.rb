class CreateLicenses < ActiveRecord::Migration
  def change
    create_table :licenses do |t|
      t.text :data, null: false

      t.timestamps
    end
  end
end
