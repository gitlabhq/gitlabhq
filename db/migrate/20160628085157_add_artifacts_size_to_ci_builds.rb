class AddArtifactsSizeToCiBuilds < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column(:ci_builds, :artifacts_size, :integer)
  end
end
