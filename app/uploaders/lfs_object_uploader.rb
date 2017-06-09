class LfsObjectUploader < GitlabUploader
  storage :file

  def store_dir
    "#{Gitlab.config.lfs.storage_path}/#{model.oid[0, 2]}/#{model.oid[2, 2]}"
  end

  def cache_dir
    "#{Gitlab.config.lfs.storage_path}/tmp/cache"
  end

  def filename
    model.oid[4..-1]
  end

  def work_dir
    File.join(Gitlab.config.lfs.storage_path, 'tmp', 'work')
  end

  private

  # To prevent LFS files from moving across filesystems, override the default
  # implementation:
  # http://github.com/carrierwaveuploader/carrierwave/blob/v1.0.0/lib/carrierwave/uploader/cache.rb#L181-L183
  def workfile_path(for_file = original_filename)
    # To be safe, keep this directory outside of the the cache directory
    # because calling CarrierWave.clean_cache_files! will remove any files in
    # the cache directory.
    File.join(work_dir, @cache_id, version_name.to_s, for_file)
  end
end
