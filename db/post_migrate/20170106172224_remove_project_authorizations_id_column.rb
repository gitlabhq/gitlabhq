# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveProjectAuthorizationsIdColumn < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :project_authorizations, :id, :primary_key
  end
end
