# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FillRoutesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'No new namespaces should be created during data copy'

  def up
    execute <<-EOF
      INSERT INTO routes
      (source_id, source_type, path)
      (SELECT id, 'Namespace', path FROM namespaces)
    EOF
  end

  def down
    execute("DELETE FROM routes WHERE source_type = 'Namespace'")
  end
end
