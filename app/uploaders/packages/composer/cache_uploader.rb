# frozen_string_literal: true
class Packages::Composer::CacheUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_options Gitlab.config.packages

  after :store, :schedule_background_upload

  alias_method :upload, :model

  def filename
    "#{model.file_sha256}.json"
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    raise ObjectNotReadyError, 'Package model not ready' unless model.id

    Gitlab::HashedPath.new("packages", "composer_cache", model.namespace_id, root_hash: model.namespace_id)
  end
end
