class MigrateCiBuildsArtifactsSize < ActiveRecord::Migration
  DOWNTIME = false

  def up
    GitlabMigrations::ArtifactsSizeWorker.perform_async
  end
end
