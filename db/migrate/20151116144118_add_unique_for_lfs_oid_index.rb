class AddUniqueForLfsOidIndex < ActiveRecord::Migration
  def change
    remove_index :lfs_objects, :oid
    remove_index :lfs_objects, [:oid, :size]
    add_index :lfs_objects, :oid, unique: true
  end
end
