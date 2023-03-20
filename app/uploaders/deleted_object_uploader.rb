# frozen_string_literal: true

class DeletedObjectUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_location :artifacts

  def store_dir
    model.store_dir
  end
end
