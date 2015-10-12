class AddArtifactsFileToBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :artifact_file, :text
  end
end
