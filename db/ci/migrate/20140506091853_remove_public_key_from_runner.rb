class RemovePublicKeyFromRunner < ActiveRecord::Migration
  def change
    remove_column :runners, :public_key
  end
end
