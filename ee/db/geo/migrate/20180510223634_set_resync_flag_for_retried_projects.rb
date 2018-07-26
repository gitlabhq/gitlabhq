class SetResyncFlagForRetriedProjects < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE project_registry SET resync_repository = 't' WHERE repository_retry_count > 0 AND resync_repository = 'f';
      UPDATE project_registry SET resync_wiki = 't' WHERE wiki_retry_count > 0 AND resync_wiki = 'f';
    SQL
  end
end
