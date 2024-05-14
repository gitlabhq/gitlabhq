# frozen_string_literal: true
class Packages::Debian::DistributionReleaseFileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern
  include Packages::GcsSignedUrlMetadata

  storage_location :packages

  alias_method :upload, :model

  def filename
    case mounted_as
    when :signed_file
      'InRelease'
    else
      'Release'
    end
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
