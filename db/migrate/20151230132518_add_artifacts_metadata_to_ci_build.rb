class AddArtifactsMetadataToCiBuild < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :artifacts_metadata, :text
  end
end
