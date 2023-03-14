# frozen_string_literal: true

class LfsObjectUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_location :lfs

  alias_method :upload, :model

  def filename
    model.oid[4..]
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    File.join(model.oid[0, 2], model.oid[2, 2])
  end
end
