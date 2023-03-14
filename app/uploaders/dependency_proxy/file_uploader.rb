# frozen_string_literal: true

class DependencyProxy::FileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  before :cache, :set_content_type
  storage_location :dependency_proxy

  alias_method :upload, :model

  def filename
    model.file_name
  end

  def store_dir
    dynamic_segment
  end

  private

  # Docker manifests return a custom content type
  # GCP will only use the content-type that is stored with the file
  # and will not allow it to be overwritten when downloaded
  # so we must store the custom content type in object storage.
  # This does not apply to DependencyProxy::Blob uploads.
  def set_content_type(file)
    return unless model.instance_of?(DependencyProxy::Manifest)

    file.content_type = model.content_type
  end

  def dynamic_segment
    Gitlab::HashedPath.new('dependency_proxy', model.group_id, 'files', model.id, root_hash: model.group_id)
  end
end
