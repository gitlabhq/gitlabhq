# frozen_string_literal: true

class RecalculateSiteStatistics < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    transaction do
      execute('SET LOCAL statement_timeout TO 0') # see https://gitlab.com/gitlab-org/gitlab-foss/issues/48967

      execute("UPDATE site_statistics SET repositories_count = (SELECT COUNT(*) FROM projects)")
    end

    transaction do
      execute('SET LOCAL statement_timeout TO 0') # see https://gitlab.com/gitlab-org/gitlab-foss/issues/48967

      execute("UPDATE site_statistics SET wikis_count = (SELECT COUNT(*) FROM project_features WHERE wiki_access_level != 0)")
    end
  end

  def down
    # No downside in keeping the counter up-to-date
  end
end
