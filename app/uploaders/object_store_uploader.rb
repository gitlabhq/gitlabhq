require 'fog/aws'
require 'carrierwave/storage/fog'

class ObjectStoreUploader < CarrierWave::Uploader::Base
  before :store, :set_default_local_store
  before :store, :verify_license!

  LOCAL_STORE = 1
  REMOTE_STORE = 2

  class << self
    def storage_options(options)
      @storage_options = options
    end

    def object_store_options
      @storage_options&.object_store
    end

    def object_store_enabled?
      object_store_options&.enabled
    end

    def object_store_credentials
      @object_store_credentials ||= object_store_options&.connection&.to_hash&.deep_symbolize_keys
    end

    def object_store_directory
      object_store_options&.remote_directory
    end
  end

  attr_reader :subject, :field

  def initialize(subject, field)
    @subject = subject
    @field = field
  end

  def file_storage?
    storage.is_a?(CarrierWave::Storage::File)
  end

  def file_cache_storage?
    cache_storage.is_a?(CarrierWave::Storage::File)
  end

  def real_object_store
    subject.public_send(:"#{field}_store")
  end

  def object_store
    real_object_store || LOCAL_STORE
  end

  def object_store=(value)
    @storage = nil
    subject.public_send(:"#{field}_store=", value)
  end

  def use_file
    if file_storage?
      return yield path
    end

    begin
      cache_stored_file!
      yield cache_path
    ensure
      cache_storage.delete_dir!(cache_path(nil))
    end
  end

  def filename
    super || file&.filename
  end

  def migrate!(new_store)
    raise 'Undefined new store' unless new_store

    return unless object_store != new_store
    return unless file

    old_file = file
    old_store = object_store

    # for moving remote file we need to first store it locally
    cache_stored_file! unless file_storage?

    # change storage
    self.object_store = new_store

    storage.store!(file).tap do |new_file|
      # since we change storage store the new storage
      # in case of failure delete new file
      begin
        subject.save!
      rescue => e
        new_file.delete
        self.object_store = old_store
        raise e
      end

      old_file.delete
    end
  end

  def fog_directory
    self.class.object_store_directory
  end

  def fog_credentials
    self.class.object_store_credentials
  end

  def fog_public
    false
  end

  def move_to_store
    return true if object_store == LOCAL_STORE

    file.try(:storage) == storage
  end

  def move_to_cache
    return true if object_store == LOCAL_STORE

    file.try(:storage) == cache_storage
  end

  # We block storing artifacts on Object Storage, not receiving
  def verify_license!(new_file)
    return if file_storage?

    raise 'Object Storage feature is missing' unless subject.project.feature_available?(:object_storage)
  end

  def exists?
    file.try(:exists?)
  end

  # Override this if you don't want to save local files by default to the Rails.root directory
  def work_dir
    # Default path set by CarrierWave:
    # https://github.com/carrierwaveuploader/carrierwave/blob/v1.1.0/lib/carrierwave/uploader/cache.rb#L182
    CarrierWave.tmp_path
  end

  private

  def set_default_local_store(new_file)
    self.object_store = LOCAL_STORE unless self.real_object_store
  end

  def storage
    @storage ||=
      if object_store == REMOTE_STORE
        remote_storage
      else
        local_storage
      end
  end

  def remote_storage
    raise 'Object Storage is not enabled' unless self.class.object_store_enabled?

    CarrierWave::Storage::Fog.new(self)
  end

  def local_storage
    CarrierWave::Storage::File.new(self)
  end

  # To prevent files in local storage from moving across filesystems, override
  # the default implementation:
  # http://github.com/carrierwaveuploader/carrierwave/blob/v1.1.0/lib/carrierwave/uploader/cache.rb#L181-L183
  def workfile_path(for_file = original_filename)
    # To be safe, keep this directory outside of the the cache directory
    # because calling CarrierWave.clean_cache_files! will remove any files in
    # the cache directory.
    File.join(work_dir, @cache_id, version_name.to_s, for_file)
  end
end
