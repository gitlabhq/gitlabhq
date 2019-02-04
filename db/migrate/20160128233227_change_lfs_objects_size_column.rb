class ChangeLfsObjectsSizeColumn < ActiveRecord::Migration[4.2]
  def change
    change_column :lfs_objects, :size, :integer, limit: 8
  end
end
