class AddArtifactsFileStorageToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :artifacts_storage, :integer
  end
end
