# frozen_string_literal: true
class Packages::Debian::ComponentFileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern
  include Packages::GcsSignedUrlMetadata

  storage_location :packages

  alias_method :upload, :model

  def filename
    model.file_name
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    raise ObjectNotReadyError, 'Package model not ready' unless model.id && model.component.distribution.container_id

    Gitlab::HashedPath.new("debian_#{model.class.container_type}_component_file", model.id, root_hash: model.component.distribution.container_id)
  end
end
