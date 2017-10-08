# rubocop:disable all
class RenameOwnerToCreatorForProject < ActiveRecord::Migration[4.2]
  def change
    rename_column :projects, :owner_id, :creator_id
  end
end
