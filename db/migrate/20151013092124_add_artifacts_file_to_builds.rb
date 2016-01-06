class AddArtifactsFileToBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :artifacts_file, :text
  end
end
