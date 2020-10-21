# frozen_string_literal: true

class DeletedObjectUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_options Gitlab.config.artifacts

  def store_dir
    model.store_dir
  end
end
