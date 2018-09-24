# frozen_string_literal: true

class JobArtifactUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  ObjectNotReadyError = Class.new(StandardError)
  UnknownFileLocationError = Class.new(StandardError)

  storage_options Gitlab.config.artifacts

  def cached_size
    return model.size if model.size.present? && !model.file_changed?

    size
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    raise ObjectNotReadyError, 'JobArtifact is not ready' unless model.id

    if model.hashed_path?
      hashed_path
    elsif model.legacy_path?
      legacy_path
    else
      raise UnknownFileLocationError
    end
  end

  def hashed_path
    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
      model.created_at.utc.strftime('%Y_%m_%d'), model.job_id.to_s, model.id.to_s)
  end

  def legacy_path
    File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.job_id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
  end
end
