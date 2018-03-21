class LfsObjectUploader < GitlabUploader
  extend Workhorse::UploadPath

  # LfsObject are in `tmp/upload` instead of `tmp/uploads`
  def self.workhorse_upload_path
    File.join(root, 'tmp/upload')
  end

  storage_options Gitlab.config.lfs

  def filename
    model.oid[4..-1]
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    File.join(model.oid[0, 2], model.oid[2, 2])
  end
end
