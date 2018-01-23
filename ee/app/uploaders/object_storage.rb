require 'fog/aws'
require 'carrierwave/storage/fog'

#
# This concern should add object storage support
# to the GitlabUploader class
#
module ObjectStorage
  RemoteStoreError = Class.new(StandardError)
  UnknownStoreError = Class.new(StandardError)
  ObjectStoreUnavailable = Class.new(StandardError)

  module Store
    LOCAL = 1
    REMOTE = 2
  end

  module Extension
    # this extension is the glue between the ObjectStorage::Concern and RecordsUploads::Concern
    module RecordsUploads
      extend ActiveSupport::Concern

      prepended do |base|
        raise ObjectStoreUnavailable, "#{base} must include ObjectStorage::Concern to use extensions."  unless base < Concern

        base.include(::RecordsUploads::Concern)
      end

      def retrieve_from_store!(identifier)
        paths = store_dirs.map { |store, path| File.join(path, identifier) }

        unless current_upload_satisfies?(paths, model)
          # we already have the right upload, don't fetch
          self.upload = uploads.find_by(model: model, path: paths)
        end

        super
      end

      def build_upload_from_uploader(uploader)
        super.tap { |upload| upload.store = object_store }
      end

      def upload=(upload)
        return unless upload

        self.object_store = upload.store
        super
      end

      private

      def current_upload_satisfies?(paths, model)
        return false unless upload
        return false unless model

        paths.include?(upload.path) &&
          upload.model_id == model.id &&
          upload.model_type == model.class.to_s
      end
    end
  end

  module Concern
    extend ActiveSupport::Concern

    included do |base|
      base.include(ObjectStorage)

      before :store, :verify_license!
      after :migrate, :delete_migrated_file
    end

    class_methods do
      def object_store_options
        storage_options&.object_store
      end

      def object_store_enabled?
        object_store_options&.enabled
      end

      def background_upload_enabled?
        object_store_options&.background_upload
      end

      def object_store_credentials
        object_store_options&.connection&.to_hash&.deep_symbolize_keys
      end

      def remote_store_path
        object_store_options&.remote_directory
      end

      def licensed?
        License.feature_available?(:object_storage)
      end
    end

    def file_storage?
      storage.is_a?(CarrierWave::Storage::File)
    end

    def file_cache_storage?
      cache_storage.is_a?(CarrierWave::Storage::File)
    end

    def object_store
      @object_store ||= model.try(store_serialization_column) || Store::LOCAL
    end

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def object_store=(value)
      @object_store = value || Store::LOCAL
      @storage = storage_for(object_store)
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    # Return true if the current file is part or the model (i.e. is mounted in the model)
    #
    def persist_object_store?
      model.respond_to?(:"#{store_serialization_column}=")
    end

    # Save the current @object_store to the model <mounted_as>_store column
    def persist_object_store!
      return unless persist_object_store?

      updated = model.update_column(store_serialization_column, object_store)
      raise ActiveRecordError unless updated
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

    #
    # Move the file to another store
    #
    #   new_store: Enum (Store::LOCAL, Store::REMOTE)
    #
    def migrate!(new_store)
      return unless object_store != new_store
      return unless file

      new_file = nil
      file_to_delete = file
      from_object_store = object_store
      self.object_store = new_store # changes the storage and file

      cache_stored_file! if file_storage?

      with_callbacks(:migrate, file_to_delete) do
        with_callbacks(:store, file_to_delete) do # for #store_versions!
          new_file = storage.store!(file)
          persist_object_store!
          self.file = new_file
        end
      end

      file
    rescue => e
      # in case of failure delete new file
      new_file.delete unless new_file.nil?
      # revert back to the old file
      self.object_store = from_object_store
      self.file = file_to_delete
      raise e
    end

    def schedule_migration_to_object_storage(*args)
      return unless self.class.object_store_enabled?
      return unless self.class.background_upload_enabled?
      return unless self.class.licensed?
      return unless self.file_storage?

      ObjectStorageUploadWorker.perform_async(self.class.name, model.class.name, mounted_as, model.id)
    end

    def fog_directory
      self.class.remote_store_path
    end

    def fog_credentials
      self.class.object_store_credentials
    end

    def fog_public
      false
    end

    def move_to_store
      false
    end

    def move_to_cache
      false
    end

    def delete_migrated_file(migrated_file)
      migrated_file.delete if exists?
    end

    def verify_license!(_file)
      return if file_storage?

      raise 'Object Storage feature is missing' unless self.class.licensed?
    end

    def exists?
      file.present?
    end

    def cache_dir
      File.join(root, base_dir, 'tmp/cache')
    end

    # Override this if you don't want to save local files by default to the Rails.root directory
    def work_dir
      # Default path set by CarrierWave:
      # https://github.com/carrierwaveuploader/carrierwave/blob/v1.1.0/lib/carrierwave/uploader/cache.rb#L182
      # CarrierWave.tmp_path
      File.join(root, base_dir, 'tmp/work')
    end

    def store_dir(store = nil)
      store_dirs[store || object_store]
    end

    def store_dirs
      {
        Store::LOCAL => File.join(base_dir, dynamic_segment),
        Store::REMOTE => File.join(dynamic_segment)
      }
    end

    private

    # this is a hack around CarrierWave. The #migrate method needs to be
    # able to force the current file to the migrated file upon success.
    def file=(file)
      @file = file
    end

    def serialization_column
      model.class.uploader_options.dig(mounted_as, :mount_on) || mounted_as
    end

    # Returns the column where the 'store' is saved
    #   defaults to 'store'
    def store_serialization_column
      [serialization_column, 'store'].compact.join('_').to_sym
    end

    def storage
      @storage ||= storage_for(object_store)
    end

    def storage_for(store)
      case store
      when Store::REMOTE
        raise 'Object Storage is not enabled' unless self.class.object_store_enabled?

        CarrierWave::Storage::Fog.new(self)
      when Store::LOCAL
        CarrierWave::Storage::File.new(self)
      else
        raise UnknownStoreError
      end
    end

    # To prevent files in local storage from moving across filesystems, override
    # the default implementation:
    # http://github.com/carrierwaveuploader/carrierwave/blob/v1.1.0/lib/carrierwave/uploader/cache.rb#L181-L183
    def workfile_path(for_file = original_filename)
      # To be safe, keep this directory outside of the the cache directory
      # because calling CarrierWave.clean_cache_files! will remove any files in
      # the cache directory.
      File.join(work_dir, cache_id, version_name.to_s, for_file)
    end
  end
end
