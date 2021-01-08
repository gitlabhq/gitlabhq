# frozen_string_literal: true
class Packages::Debian::DistributionReleaseFileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_options Gitlab.config.packages

  after :store, :schedule_background_upload

  alias_method :upload, :model

  def filename
    'Release'
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    raise ObjectNotReadyError, 'Package model not ready' unless model.id

    Gitlab::HashedPath.new("debian_#{model.class.container_type}_distribution", model.id, root_hash: model.container_id)
  end
end
