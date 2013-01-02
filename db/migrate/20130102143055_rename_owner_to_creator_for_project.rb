class RenameOwnerToCreatorForProject < ActiveRecord::Migration
  def change
    rename_column :projects, :owner_id, :creator_id
  end
end
