class GitlabUploader < CarrierWave::Uploader::Base
  def self.absolute_path(upload_record)
    File.join(CarrierWave.root, upload_record.path)
  end

  def self.base_dir
    'uploads'
  end

  delegate :base_dir, to: :class

  def file_storage?
    storage.is_a?(CarrierWave::Storage::File)
  end

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

  def use_file
    yield path
  end

  def exists?
    file.try(:exists?)
  end
end
