class GitlabUploader < CarrierWave::Uploader::Base
  class_attribute :options

  class << self
    # DSL setter
    def storage_options(options)
      self.options = options
    end

    def root
      options.storage_path
    end

    # represent the directory namespacing at the class level
    def base_dir
      options.fetch('base_dir', '')
    end

    def file_storage?
      storage == CarrierWave::Storage::File
    end

    def absolute_path(upload_record)
      File.join(root, upload_record.path)
    end
  end

  storage_options Gitlab.config.uploads

  delegate :base_dir, :file_storage?, to: :class

  def initialize(model, mounted_as = nil, **uploader_context)
    super(model, mounted_as)
  end

  def file_cache_storage?
    cache_storage.is_a?(CarrierWave::Storage::File)
  end

  # Reduce disk IO
  def move_to_cache
    file_storage?
  end

  # Reduce disk IO
  def move_to_store
    file_storage?
  end

  def exists?
    file.present?
  end

  def store_dir
    File.join(base_dir, dynamic_segment)
  end

  def cache_dir
    File.join(root, base_dir, 'tmp/cache')
  end

  def work_dir
    File.join(root, base_dir, 'tmp/work')
  end

  def filename
    super || file&.filename
  end

  def model_valid?
    !!model
  end

  private

  # Designed to be overridden by child uploaders that have a dynamic path
  # segment -- that is, a path that changes based on mutable attributes of its
  # associated model
  def dynamic_segment
    raise(NotImplementedError)
  end

  # To prevent files from moving across filesystems, override the default
  # implementation:
  # http://github.com/carrierwaveuploader/carrierwave/blob/v1.0.0/lib/carrierwave/uploader/cache.rb#L181-L183
  def workfile_path(for_file = original_filename)
    # To be safe, keep this directory outside of the the cache directory
    # because calling CarrierWave.clean_cache_files! will remove any files in
    # the cache directory.
    File.join(work_dir, cache_id, version_name.to_s, for_file)
  end
end
