class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.integer  :user_id, null: false
      t.string   :email, null: false
      
      t.timestamps
    end

    add_index :emails, :user_id
    add_index :emails, :email, unique: true
  end
end
