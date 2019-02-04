class AddArtifactsFileToBuilds < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :artifacts_file, :text
  end
end
