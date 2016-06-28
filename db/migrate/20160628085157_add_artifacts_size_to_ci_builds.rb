# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddArtifactsSizeToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column(:ci_builds, :artifacts_size, :integer)
  end
end
