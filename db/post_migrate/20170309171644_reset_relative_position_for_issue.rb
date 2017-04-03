# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ResetRelativePositionForIssue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    update_column_in_batches(:issues, :relative_position, nil) do |table, query|
      query.where(table[:relative_position].not_eq(nil))
    end
  end

  def down
  end
end
