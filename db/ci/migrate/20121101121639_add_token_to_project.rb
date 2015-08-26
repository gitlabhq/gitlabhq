class AddTokenToProject < ActiveRecord::Migration
  def change
    add_column :projects, :token, :string, null: true
  end
end
