class AddBeforeShaToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :before_sha, :string, null: true
  end
end
