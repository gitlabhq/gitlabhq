class LfsObjectUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_options Gitlab.config.lfs

  def store_dir
    dynamic_segment
  end

  def filename
    model.oid[4..-1]
  end

  private

  def dynamic_segment
    File.join(model.oid[0, 2], model.oid[2, 2])
  end
end
