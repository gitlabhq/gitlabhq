# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRepositoryCheckToGeoProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_registry, :last_repository_check_failed, :boolean
    add_column :project_registry, :last_repository_check_at, :datetime_with_timezone
  end
end
