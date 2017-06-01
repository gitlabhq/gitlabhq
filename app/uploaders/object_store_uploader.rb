require 'fog/aws'
require 'carrierwave/storage/fog'

class ObjectStoreUploader < GitlabUploader
  before :store, :set_default_local_store

  LOCAL_STORE = 1
  REMOTE_STORE = 2

  def object_store
    subject.public_send(:"#{field}_store")
  end

  def object_store=(value)
    @storage = nil
    subject.public_send(:"#{field}_store=", value)
  end

  def self.storage_options(options)
    @storage_options = options
  end

  def self.object_store_options
    @storage_options&.object_store
  end

  def self.object_store_enabled?
    object_store_options&.enabled
  end

  def use_file
    unless object_store == REMOTE_STORE
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

    # change storage
    self.object_store = new_store

    # store file on a new storage
    new_file = storage.store!(old_file)

    # since we change storage store the new storage
    # in case of failure delete new file
    begin
      subject.save!
    rescue
      self.object_store = old_store
      new_file.delete
    end

    old_file.delete
  end

  def move_to_store
    object_store != REMOTE_STORE
  end

  def move_to_cache
    false
  end

  def fog_directory
    self.class.object_store_options.bucket
  end

  def fog_credentials
    object_store_options = self.class.object_store_options
    {
      provider:              object_store_options.provider,
      aws_access_key_id:     object_store_options.access_key_id,
      aws_secret_access_key: object_store_options.secret_access_key,
      region:                object_store_options.region,
      endpoint:              object_store_options.endpoint,
      path_style:            true
    }
  end

  def fog_public
    false
  end

  private

  def set_default_local_store(new_file)
    object_store ||= LOCAL_STORE
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
end
