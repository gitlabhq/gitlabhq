class JobArtifactUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  ObjectNotReadyError = Class.new(StandardError)

  storage_options Gitlab.config.artifacts

  def cached_size
    return model.size if model.size.present? && !model.file_changed?

    size
  end

  def store_dir
    dynamic_segment
  end

  def open
    if file_storage?
      File.open(path, "rb") if path
    else
      ::Gitlab::Ci::Trace::HttpIO.new(url, cached_size) if url
    end
  end

  private

  def dynamic_segment
    raise ObjectNotReadyError, 'JobArtifact is not ready' unless model.id

    creation_date = model.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, model.job_id.to_s, model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
  end
end
