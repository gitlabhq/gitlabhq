# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixPoolRepositorySourceProjectId < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    execute "UPDATE pool_repositories SET source_project_id = (SELECT MIN(id) FROM projects WHERE pool_repository_id = pool_repositories.id) WHERE pool_repositories.source_project_id IS NULL"
  end

  def down
    # nothing to do her
  end
end
