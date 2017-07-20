class GitlabUploader < CarrierWave::Uploader::Base
  def self.absolute_path(upload_record)
    File.join(CarrierWave.root, upload_record.path)
  end

  def self.root_dir
    'uploads'
  end

  # When object storage is used, keep the `root_dir` as `base_dir`.
  # The files aren't really in folders there, they just have a name.
  # The files that contain user input in their name, also contain a hash, so
  # the names are still unique
  #
  # This method is overridden in the `FileUploader`
  def self.base_dir
    return root_dir unless file_storage?

    File.join(root_dir, '-', 'system')
  end

  def self.file_storage?
    self.storage == CarrierWave::Storage::File
  end

  delegate :base_dir, :file_storage?, to: :class

  def file_cache_storage?
    cache_storage.is_a?(CarrierWave::Storage::File)
  end

  # Reduce disk IO
  def move_to_cache
    true
  end

  # Reduce disk IO
  def move_to_store
    true
  end

  # Designed to be overridden by child uploaders that have a dynamic path
  # segment -- that is, a path that changes based on mutable attributes of its
  # associated model
  #
  # For example, `FileUploader` builds the storage path based on the associated
  # project model's `path_with_namespace` value, which can change when the
  # project or its containing namespace is moved or renamed.
  def relative_path
    self.file.path.sub("#{root}/", '')
  end

  def exists?
    file.try(:exists?)
  end

  # Override this if you don't want to save files by default to the Rails.root directory
  def work_dir
    # Default path set by CarrierWave:
    # https://github.com/carrierwaveuploader/carrierwave/blob/v1.0.0/lib/carrierwave/uploader/cache.rb#L182
    CarrierWave.tmp_path
  end

  def filename
    super || file&.filename
  end

  private

  # To prevent files from moving across filesystems, override the default
  # implementation:
  # http://github.com/carrierwaveuploader/carrierwave/blob/v1.0.0/lib/carrierwave/uploader/cache.rb#L181-L183
  def workfile_path(for_file = original_filename)
    # To be safe, keep this directory outside of the the cache directory
    # because calling CarrierWave.clean_cache_files! will remove any files in
    # the cache directory.
    File.join(work_dir, @cache_id, version_name.to_s, for_file)
  end
end
