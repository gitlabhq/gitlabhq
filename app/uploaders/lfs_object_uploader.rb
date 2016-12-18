class LfsObjectUploader < GitlabUploader
  storage :file

  def store_dir
    "#{Gitlab.config.lfs.storage_path}/#{model.oid[0, 2]}/#{model.oid[2, 2]}"
  end

  def cache_dir
    "#{Gitlab.config.lfs.storage_path}/tmp/cache"
  end

  def exists?
    file.try(:exists?)
  end

  def filename
    model.oid[4..-1]
  end
end
