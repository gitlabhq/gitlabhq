class RemoveInvalidBuild < ActiveRecord::Migration
  def change
    execute "DELETE FROM builds WHERE commit_id is NULL"
  end
end
