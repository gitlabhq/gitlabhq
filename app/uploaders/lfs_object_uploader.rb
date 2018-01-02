class LfsObjectUploader < ObjectStoreUploader
  storage_options Gitlab.config.lfs

  def self.local_store_path
    Gitlab.config.lfs.storage_path
  end

  def filename
    model.oid[4..-1]
  end

  private

  def default_path
    "#{model.oid[0, 2]}/#{model.oid[2, 2]}"
  end
end
