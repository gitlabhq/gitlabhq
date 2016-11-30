# rubocop:disable all
class CreateEmails < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :emails do |t|
      t.integer  :user_id, null: false
      t.string   :email, null: false

      t.timestamps null: true
    end

    add_index :emails, :user_id
    add_index :emails, :email, unique: true
  end
end
