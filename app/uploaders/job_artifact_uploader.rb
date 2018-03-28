class JobArtifactUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_options Gitlab.config.artifacts

  def size
    return super if model.size.nil?

    model.size
  end

  def store_dir
    dynamic_segment
  end

  def open
    if file_storage?
      File.open(path, "rb") if path
    else
      ::Gitlab::Ci::Trace::RemoteFile.new(model.job_id, url, size, "rb") if url
    end
  end

  private

  def dynamic_segment
    creation_date = model.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, model.job_id.to_s, model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
  end
end
