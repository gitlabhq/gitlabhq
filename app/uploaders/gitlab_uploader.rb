# frozen_string_literal: true

class GitlabUploader < CarrierWave::Uploader::Base
  include ContentTypeWhitelist::Concern

  class_attribute :options

  PROTECTED_METHODS = %i(filename cache_dir work_dir store_dir).freeze

  ObjectNotReadyError = Class.new(StandardError)

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

  before :cache, :protect_from_path_traversal!

  def initialize(model, mounted_as = nil, **uploader_context)
    super(model, mounted_as)
  end

  def file_cache_storage?
    cache_storage.is_a?(CarrierWave::Storage::File)
  end

  def move_to_cache
    file_storage?
  end

  def move_to_store
    file_storage?
  end

  def exists?
    file.present?
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

  def relative_path
    return path if pathname.relative?

    pathname.relative_path_from(Pathname.new(root))
  end

  def model_valid?
    !!model
  end

  def local_url
    File.join('/', self.class.base_dir, dynamic_segment, filename)
  end

  def cached_size
    size
  end

  def open
    stream =
      if file_storage?
        File.open(path, "rb") if path
      else
        ::Gitlab::HttpIO.new(url, cached_size) if url
      end

    return unless stream
    return stream unless block_given?

    begin
      yield(stream)
    ensure
      stream.close
    end
  end

  # Used to replace an existing upload with another +file+ without modifying stored metadata
  # Use this method only to repair/replace an existing upload, or to upload to a Geo secondary node
  #
  # @param [CarrierWave::SanitizedFile] file that will replace existing upload
  # @return CarrierWave::SanitizedFile
  def replace_file_without_saving!(file)
    raise ArgumentError, 'should be a CarrierWave::SanitizedFile' unless file.is_a? CarrierWave::SanitizedFile

    storage.store!(file)
  end

  def url_or_file_path(url_options = {})
    if file_storage?
      'file://' + path
    else
      url(url_options)
    end
  end

  private

  # Designed to be overridden by child uploaders that have a dynamic path
  # segment -- that is, a path that changes based on mutable attributes of its
  # associated model
  #
  # For example, `FileUploader` builds the storage path based on the associated
  # project model's `path_with_namespace` value, which can change when the
  # project or its containing namespace is moved or renamed.
  #
  # When implementing this method, raise `ObjectNotReadyError` if the model
  # does not yet exist, as it will be tested in `#protect_from_path_traversal!`
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

  def pathname
    @pathname ||= Pathname.new(path)
  end

  # Protect against path traversal attacks
  # This takes a list of methods to test for path traversal, e.g. ../../
  # and checks each of them. This uses `.send` so that any potential errors
  # don't block the entire set from being tested.
  #
  # @param [CarrierWave::SanitizedFile]
  # @return [Nil]
  # @raise [Gitlab::Utils::PathTraversalAttackError]
  def protect_from_path_traversal!(file)
    PROTECTED_METHODS.each do |method|
      Gitlab::Utils.check_path_traversal!(self.send(method)) # rubocop: disable GitlabSecurity/PublicSend

    rescue ObjectNotReadyError
      # Do nothing. This test was attempted before the file was ready for that method
    end
  end
end
