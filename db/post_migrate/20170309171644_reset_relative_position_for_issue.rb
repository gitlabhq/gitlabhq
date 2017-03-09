# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ResetRelativePositionForIssue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute <<-EOS
      UPDATE issues SET relative_position = NULL
        WHERE issues.relative_position IS NOT NULL;
    EOS
  end

  def down
  end
end
