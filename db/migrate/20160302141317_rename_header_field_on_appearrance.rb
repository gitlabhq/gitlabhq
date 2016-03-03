class RenameHeaderFieldOnAppearrance < ActiveRecord::Migration
  def change
    rename_column :appearances, :light_logo, :header_logo

    remove_column :appearances, :dark_logo
  end
end
