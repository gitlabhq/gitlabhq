class AddIndexForLfsOidAndSize < ActiveRecord::Migration
  def change
    add_index :lfs_objects, :oid
    add_index :lfs_objects, [:oid, :size]
  end
end
