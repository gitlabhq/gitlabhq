class RenameBuildboxService < ActiveRecord::Migration
  def up
    execute "UPDATE services SET type = 'BuildkiteService' WHERE type = 'BuildboxService';"
  end

  def down
    execute "UPDATE services SET type = 'BuildboxService' WHERE type = 'BuildkiteService';"
  end
end
