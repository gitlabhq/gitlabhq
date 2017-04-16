# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpateLatestForCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  
  disable_ddl_transaction!

  def up
    disable_statement_timeout

    execute <<-SQL.strip_heredoc
      UPDATE ci_builds SET latest = false
        WHERE latest = true
          AND id NOT IN (SELECT MAX(id) FROM ci_builds GROUP BY commit_id, name)
    SQL
  end

  def down
  end
end
