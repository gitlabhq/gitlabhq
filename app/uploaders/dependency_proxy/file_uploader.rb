# frozen_string_literal: true

class DependencyProxy::FileUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_options Gitlab.config.dependency_proxy

  alias_method :upload, :model

  def filename
    model.file_name
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    Gitlab::HashedPath.new('dependency_proxy', model.group_id, 'files', model.id, root_hash: model.group_id)
  end
end
