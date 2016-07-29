class RenameHeaderFieldOnAppearrance < ActiveRecord::Migration
  def up
    unless column_exists?(:appearances, :header_logo)
      rename_column :appearances, :light_logo, :header_logo
    end

    if column_exists?(:appearances, :dark_logo)
      remove_column :appearances, :dark_logo
    end
  end

  def down
    rename_column(:appearances, :header_logo, :light_logo)
    add_column(:appearances, :dark_logo, :string)
  end
end
