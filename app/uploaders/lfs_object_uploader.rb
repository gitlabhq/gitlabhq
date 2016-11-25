class LfsObjectUploader < CarrierWave::Uploader::Base
  storage :aws

  aws_bucket :shared

  def store_dir
    #"#{Gitlab.config.lfs.storage_path}/#{model.oid[0, 2]}/#{model.oid[2, 2]}"
    "lfs-objects/#{model.oid[0, 2]}/#{model.oid[2, 2]}"
  end

  def cache_dir
    # "#{Gitlab.config.lfs.storage_path}/tmp/cache"
    'lf-objects/tmp/cache'
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
