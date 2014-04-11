class IndexOnCurrentSignInAt < ActiveRecord::Migration
  def change
    add_index :users, :current_sign_in_at
  end
end
