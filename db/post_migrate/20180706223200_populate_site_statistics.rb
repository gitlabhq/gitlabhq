class PopulateSiteStatistics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    transaction do
      execute('SET LOCAL statement_timeout TO 0') if Gitlab::Database.postgresql? # see https://gitlab.com/gitlab-org/gitlab-ce/issues/48967

      execute("UPDATE site_statistics SET repositories_count = (SELECT COUNT(*) FROM projects)")
    end

    transaction do
      execute('SET LOCAL statement_timeout TO 0') if Gitlab::Database.postgresql? # see https://gitlab.com/gitlab-org/gitlab-ce/issues/48967

      execute("UPDATE site_statistics SET wikis_count = (SELECT COUNT(*) FROM project_features WHERE wiki_access_level != 0)")
    end
  end

  def down
    # No downside in keeping the counter up-to-date
  end
end
