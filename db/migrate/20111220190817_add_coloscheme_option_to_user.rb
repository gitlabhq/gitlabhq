class AddColoschemeOptionToUser < ActiveRecord::Migration
  def change
    add_column :users, :dark_scheme, :boolean, :default => false, :null => false
  end
end
