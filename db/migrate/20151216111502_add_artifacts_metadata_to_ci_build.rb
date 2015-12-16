class AddArtifactsMetadataToCiBuild < ActiveRecord::Migration
  def change
    add_column :ci_builds, :artifacts_metadata, :text, limit: 4294967295
  end
end
