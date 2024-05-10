# frozen_string_literal: true
class Packages::PackageFileUploader < GitlabUploader
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
    raise ObjectNotReadyError, "Package model not ready" unless model.id

    Gitlab::HashedPath.new('packages', model.package_id, 'files', model.id, root_hash: model.package.project_id)
  end
end
