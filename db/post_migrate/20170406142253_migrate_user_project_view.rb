# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateUserProjectView < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    update_column_in_batches(:users, :project_view, 2) do |table, query|
      query.where(table[:project_view].eq(0))
    end
  end

  def down
    # Nothing can be done to restore old values
  end
end
