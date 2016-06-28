# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddArtifactsSizesToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    # Or :json if under PostgreSQL?
    add_column(:ci_builds, :artifacts_sizes, :text)
  end
end
