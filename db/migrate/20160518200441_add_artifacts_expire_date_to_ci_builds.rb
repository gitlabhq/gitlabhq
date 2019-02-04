# rubocop:disable Migration/Datetime
class AddArtifactsExpireDateToCiBuilds < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :artifacts_expire_at, :timestamp
  end
end
