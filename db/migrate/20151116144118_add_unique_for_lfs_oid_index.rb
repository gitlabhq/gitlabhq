# rubocop:disable all
class AddUniqueForLfsOidIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index :lfs_objects, :oid
    remove_index :lfs_objects, [:oid, :size]
    add_index :lfs_objects, :oid, unique: true
  end
end
