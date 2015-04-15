class AddPublicEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_email, :string, default: "", null: false
  end
end
