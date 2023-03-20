# frozen_string_literal: true

class JobArtifactUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern
  include ObjectStorage::CDN::Concern

  UnknownFileLocationError = Class.new(StandardError)

  storage_location :artifacts

  alias_method :upload, :model

  def cached_size
    return model.size if model.size.present? && !model.file_changed?

    size
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    # This now tests model.created_at because it can for some reason be nil in the test suite,
    # and it's not clear if this is intentional or not
    raise ObjectNotReadyError, 'JobArtifact is not ready' unless model.id && model.created_at

    if model.hashed_path?
      hashed_path
    elsif model.legacy_path?
      legacy_path
    else
      raise UnknownFileLocationError
    end
  end

  def hashed_path
    Gitlab::HashedPath.new(model.created_at.utc.strftime('%Y_%m_%d'), model.job_id, model.id, root_hash: model.project_id)
  end

  def legacy_path
    File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.job_id.to_s)
  end
end
