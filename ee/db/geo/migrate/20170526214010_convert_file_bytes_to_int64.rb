class ConvertFileBytesToInt64 < ActiveRecord::Migration
  def change
    change_column :file_registry, :bytes, :integer, limit: 8
  end
end
