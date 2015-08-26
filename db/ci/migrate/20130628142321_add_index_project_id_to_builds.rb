class AddIndexProjectIdToBuilds < ActiveRecord::Migration
  def change
    add_index :builds, :project_id
  end
end
