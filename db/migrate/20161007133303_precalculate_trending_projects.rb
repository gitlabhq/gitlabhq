# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PrecalculateTrendingProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :trending_projects do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
    end

    timestamp = connection.quote(1.month.ago)

    # We're hardcoding the visibility level (public) here so that if it ever
    # changes this query doesn't suddenly use the new value (which may break
    # later migrations).
    visibility = 20

    execute <<-EOF.strip_heredoc
      INSERT INTO trending_projects (project_id)
      SELECT project_id
      FROM notes
      INNER JOIN projects ON projects.id = notes.project_id
      WHERE notes.created_at >= #{timestamp}
      AND notes.system IS FALSE
      AND projects.visibility_level = #{visibility}
      GROUP BY project_id
      ORDER BY count(*) DESC
      LIMIT 100;
    EOF
  end

  def down
    drop_table :trending_projects
  end
end
