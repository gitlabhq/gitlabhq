# rubocop:disable all
class AddIndexForLfsOidAndSize < ActiveRecord::Migration[4.2]
  def change
    add_index :lfs_objects, :oid
    add_index :lfs_objects, [:oid, :size]
  end
end
