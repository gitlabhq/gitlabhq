# rubocop:disable all
class IndexOnCurrentSignInAt < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :current_sign_in_at
  end
end
