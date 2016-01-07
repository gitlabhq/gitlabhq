# encoding: utf-8

class LfsObjectUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "#{Gitlab.config.lfs.storage_path}/#{model.oid[0,2]}/#{model.oid[2,2]}"
  end

  def cache_dir
    "#{Gitlab.config.lfs.storage_path}/tmp/cache"
  end

  def move_to_cache
    true
  end

  def move_to_store
    true
  end

  def exists?
    file.try(:exists?)
  end

  def filename
    model.oid[4..-1]
  end
end
