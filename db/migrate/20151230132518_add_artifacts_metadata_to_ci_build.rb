class AddArtifactsMetadataToCiBuild < ActiveRecord::Migration
  def change
    add_column :ci_builds, :artifacts_metadata, :text
  end
end
