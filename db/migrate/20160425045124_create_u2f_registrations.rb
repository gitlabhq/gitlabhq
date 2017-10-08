# rubocop:disable all
class CreateU2fRegistrations < ActiveRecord::Migration[4.2]
  def change
    create_table :u2f_registrations do |t|
      t.text :certificate
      t.string :key_handle, index: true
      t.string :public_key
      t.integer :counter
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
