class ChangeLfsObjectsSizeColumn < ActiveRecord::Migration
  def change
    change_column :lfs_objects, :size, :integer, limit: 8
  end
end
