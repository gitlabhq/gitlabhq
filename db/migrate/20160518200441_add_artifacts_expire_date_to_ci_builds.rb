# rubocop:disable Migration/Datetime
class AddArtifactsExpireDateToCiBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :artifacts_expire_at, :timestamp
  end
end
