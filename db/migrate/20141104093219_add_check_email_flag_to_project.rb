class AddCheckEmailFlagToProject < ActiveRecord::Migration
  def change
    add_column :projects, :check_email, :boolean, default: true, null: false
  end
end
