class LegacyArtifactUploader < ObjectStoreUploader
  storage_options Gitlab.config.artifacts

  def self.local_store_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_store_path, 'tmp/uploads/')
  end

  private

  def default_path
    File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.id.to_s)
  end
end
