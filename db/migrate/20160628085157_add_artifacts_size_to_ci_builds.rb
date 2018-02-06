class AddArtifactsSizeToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column(:ci_builds, :artifacts_size, :integer)
  end
end
