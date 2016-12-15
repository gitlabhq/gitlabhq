# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FillProjectsRoutesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'No new projects should be created during data copy'

  def up
    execute <<-EOF
      INSERT INTO routes
      (source_id, source_type, path)
      (SELECT projects.id, 'Project', concat(namespaces.path, '/', projects.path) FROM projects
      INNER JOIN namespaces ON projects.namespace_id = namespaces.id)
    EOF
  end

  def down
    execute("DELETE FROM routes WHERE source_type = 'Project'")
  end
end
