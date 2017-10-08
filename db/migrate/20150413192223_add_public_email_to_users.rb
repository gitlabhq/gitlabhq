# rubocop:disable all
class AddPublicEmailToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :public_email, :string, default: "", null: false
  end
end
