# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDuplicatesFromRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # We can skip this migration when running a PostgreSQL database because
    # we use an optimized query in the "FillProjectsRoutesTable" migration
    # to fill these values that avoid duplicate entries in the routes table.
    return unless Gitlab::Database.mysql?

    execute <<-EOF
      DELETE duplicated_rows.*
      FROM routes AS duplicated_rows
        INNER JOIN (
          SELECT path, MAX(id) as max_id
          FROM routes
          GROUP BY path
          HAVING COUNT(*) > 1
        ) AS good_rows ON good_rows.path = duplicated_rows.path AND good_rows.max_id <> duplicated_rows.id;
    EOF
  end

  def down
  end
end
