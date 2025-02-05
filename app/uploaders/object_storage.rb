# frozen_string_literal: true

require 'fog/aws'
require 'carrierwave/storage/fog'

#
# This concern should add object storage support
# to the GitlabUploader class
#
module ObjectStorage
  RemoteStoreError = Class.new(StandardError)
  UnknownStoreError = Class.new(StandardError)
  ObjectStorageUnavailable = Class.new(StandardError)
  MissingFinalStorePathRootId = Class.new(StandardError)

  class ExclusiveLeaseTaken < StandardError
    def initialize(lease_key)
      @lease_key = lease_key
    end

    def message
      *lease_key_group, _ = *@lease_key.split(":")
      "Exclusive lease for #{lease_key_group.join(':')} is already taken."
    end
  end

  class DirectUploadStorage < ::CarrierWave::Storage::Fog
    extend ::Gitlab::Utils::Override

    # This override only applies to object storage uploaders (e.g JobArtifactUploader).
    # - The DirectUploadStorage is only used when object storage is enabled. See `#storage_for`
    # - This method is called in two possible ways:
    #   - When a model (e.g. JobArtifact) is saved
    #   - When uploader.replace_file_without_saving! is called directly
    #     - For example, see `Gitlab::Geo::Replication::BlobDownloader#download_file`
    # - We need this override to add the special behavior that bypasses
    #   CarrierWave's default storing mechanism, which copies a tempfile
    #   to its final location. In the case of files that are directly uploaded
    #   by Workhorse to the final location (determined by presence of `<mounted_as>_final_path`) in
    #   the object storage, the extra copy/delete step of CarrierWave
    #   is unnecessary.
    # - We also need to ensure to only bypass the default store behavior if the file given
    #   is a `CarrierWave::Storage::Fog::File` (uploaded to object storage) and with `<mounted_as>_final_path`
    #   defined. For everything else, we want to still use the default CarrierWave storage behavior.
    #   - For example, during Geo replication of job artifacts, `replace_file_without_saving!` is
    #     called with a sanitized Tempfile. In this case, we want to use the default behavior of
    #     moving the tempfile to its final location and let CarrierWave upload the file to object storage.
    override :store!
    def store!(file)
      return super unless file.is_a?(::CarrierWave::Storage::Fog::File)
      return super unless @uploader.direct_upload_final_path.present?

      # The direct_upload_final_path is defined which means
      # file was uploaded to its final location so no need to move it.
      # Now we delete the pending upload entry as the upload is considered complete.
      pending_upload_path = @uploader.class.without_bucket_prefix(file.path)
      ObjectStorage::PendingDirectUpload.complete(@uploader.class.storage_location_identifier, pending_upload_path)

      file
    end
  end

  TMP_UPLOAD_PATH = 'tmp/uploads'

  module Store
    LOCAL = 1
    REMOTE = 2
  end

  SUPPORTED_STORES = [Store::LOCAL, Store::REMOTE].freeze

  module Extension
    # this extension is the glue between the ObjectStorage::Concern and RecordsUploads::Concern
    module RecordsUploads
      extend ActiveSupport::Concern

      prepended do |base|
        raise "#{base} must include ObjectStorage::Concern to use extensions." unless base < Concern

        base.include(::RecordsUploads::Concern)
      end

      def retrieve_from_store!(identifier)
        paths = upload_paths(identifier)

        unless current_upload_satisfies?(paths, model)
          # the upload we already have isn't right, find the correct one
          self.upload = model&.retrieve_upload(identifier, paths)
        end

        super
      end

      def build_upload
        super.tap do |upload|
          upload.store = object_store
        end
      end

      def upload=(upload)
        return if upload.nil?

        self.object_store = upload.store
        super
      end

      def exclusive_lease_key
        # For FileUploaders, model may have many uploaders. In that case
        # we want to use exclusive key per upload, not per model to allow
        # parallel migration
        key_object = upload || model

        "object_storage_migrate:#{key_object.class}:#{key_object.id}"
      end

      private

      def current_upload_satisfies?(paths, model)
        return false unless upload
        return false unless model

        paths.include?(upload.path) &&
          upload.model_id == model.id &&
          upload.model_type == model.class.base_class.sti_name
      end
    end
  end

  module Concern
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    included do |base|
      base.include(ObjectStorage)

      after :migrate, :delete_migrated_file
    end

    class_methods do
      def object_store_options
        options.object_store
      end

      def object_store_enabled?
        object_store_options.enabled
      end

      def direct_upload_enabled?
        object_store_options&.direct_upload
      end

      def direct_upload_to_object_store?
        object_store_enabled? && direct_upload_enabled?
      end

      def proxy_download_enabled?
        object_store_options.proxy_download
      end

      def direct_download_enabled?
        !proxy_download_enabled?
      end

      def object_store_credentials
        object_store_options.connection.to_hash.deep_symbolize_keys
      end

      def remote_store_path
        object_store_options.remote_directory
      end

      def serialization_column(model_class, mount_point)
        model_class.uploader_options.dig(mount_point, :mount_on) || mount_point
      end

      def generate_remote_id
        [CarrierWave.generate_cache_id, SecureRandom.hex].join('-')
      end

      def generate_final_store_path(root_hash:)
        hash = Digest::SHA2.hexdigest(SecureRandom.uuid)

        # We prefix '@final' to prevent clashes and make the files easily recognizable
        # as having been created by this code.
        sub_path = File.join('@final', hash[0..1], hash[2..3], hash[4..])

        # We generate a hashed path of the root ID (e.g. Project ID) to distribute directories instead of
        # filling up one root directory with a bunch of files.
        Gitlab::HashedPath.new(sub_path, root_hash: root_hash).to_s
      end

      # final_store_path_config is only used if use_final_store_path is set to true
      # Two keys are available:
      # - :root_hash. The root hash used in Gitlab::HashedPath for the path generation.
      # - :override_path. If set, the path generation is skipped and this value is used instead.
      #                   Make sure that this value is unique for each upload.
      def workhorse_authorize(
        has_length:,
        maximum_size: nil,
        use_final_store_path: false,
        final_store_path_config: {})
        {}.tap do |hash|
          if self.direct_upload_to_object_store?
            hash[:RemoteObject] = workhorse_remote_upload_options(
              has_length: has_length,
              maximum_size: maximum_size,
              use_final_store_path: use_final_store_path,
              final_store_path_config: final_store_path_config
            )
          else
            hash[:TempPath] = workhorse_local_upload_path
          end

          hash[:UploadHashFunctions] = %w[sha1 sha256 sha512] if ::Gitlab::FIPS.enabled?
          hash[:MaximumSize] = maximum_size if maximum_size.present?
        end
      end

      def workhorse_local_upload_path
        File.join(self.root, TMP_UPLOAD_PATH)
      end

      def with_bucket_prefix(path)
        File.join([object_store_options.bucket_prefix, path].compact)
      end

      def without_bucket_prefix(path)
        Pathname.new(path).relative_path_from(object_store_options.bucket_prefix.to_s).to_s
      end

      def object_store_config
        ObjectStorage::Config.new(object_store_options)
      end

      def workhorse_remote_upload_options(
        has_length:,
        maximum_size: nil,
        use_final_store_path: false,
        final_store_path_config: {})
        return unless direct_upload_to_object_store?

        if use_final_store_path
          id = if final_store_path_config[:override_path].present?
                 final_store_path_config[:override_path]
               else
                 raise MissingFinalStorePathRootId unless final_store_path_config[:root_hash].present?

                 generate_final_store_path(root_hash: final_store_path_config[:root_hash])
               end

          upload_path = with_bucket_prefix(id)
          prepare_pending_direct_upload(id)
        else
          id = generate_remote_id
          upload_path = File.join(TMP_UPLOAD_PATH, id)
        end

        direct_upload = ObjectStorage::DirectUpload.new(self.object_store_config, upload_path,
          has_length: has_length, maximum_size: maximum_size, skip_delete: use_final_store_path)

        direct_upload.to_hash.merge(ID: id)
      end

      def prepare_pending_direct_upload(path)
        ObjectStorage::PendingDirectUpload.prepare(
          storage_location_identifier,
          path
        )
      end
    end

    class OpenFile
      extend Forwardable

      # Explicitly exclude :path, because rubyzip uses that to detect "real" files.
      def_delegators :@file, *(Zip::File::IO_METHODS - [:path])

      # Even though :size is not in IO_METHODS, we do need it.
      def_delegators :@file, :size

      def initialize(file)
        @file = file
      end

      def file_path
        @file.path
      end

      # CarrierWave#cache! calls filename, which calls original_filename
      def original_filename
        return File.basename(file_path) if file_path.present?

        nil
      end
    end

    def proxy_download_enabled?
      self.class.proxy_download_enabled?
    end

    def direct_download_enabled?
      self.class.direct_download_enabled?
    end

    # allow to configure and overwrite the filename
    def filename
      @filename || super || file&.filename # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def filename=(filename)
      @filename = filename # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def file_storage?
      storage.is_a?(CarrierWave::Storage::File)
    end

    def file_cache_storage?
      cache_storage.is_a?(CarrierWave::Storage::File)
    end

    def object_store
      # We use Store::LOCAL as null value indicates the local storage
      @object_store ||= model.try(store_serialization_column) || Store::LOCAL
    end

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def object_store=(value)
      @object_store = value || Store::LOCAL
      model[store_serialization_column] = @object_store if sync_model_object_store? && persist_object_store?
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
      raise 'Failed to update object store' unless updated
    end

    def use_file(&blk)
      with_exclusive_lease do
        unsafe_use_file(&blk)
      end
    end

    def use_open_file(unlink_early: true)
      Tempfile.open(path) do |file|
        file.unlink if unlink_early
        file.binmode

        if file_storage?
          IO.copy_stream(path, file)
        else
          Faraday.get(url) do |req|
            req.options.on_data = proc { |chunk, _| file.write(chunk) }
          end
        end

        file.seek(0, IO::SEEK_SET)

        yield OpenFile.new(file)
      ensure
        file.unlink unless unlink_early
      end
    end

    #
    # Move the file to another store
    #
    #   new_store: Enum (Store::LOCAL, Store::REMOTE)
    #
    def migrate!(new_store)
      with_exclusive_lease do
        unsafe_migrate!(new_store)
      end
    end

    def fog_directory
      self.class.remote_store_path
    end

    def fog_credentials
      self.class.object_store_credentials
    end

    def fog_attributes
      @fog_attributes ||= self.class.object_store_config.fog_attributes
    end

    # Set ACL of uploaded objects to not-public (fog-aws)[1] or no ACL at all
    # (fog-google).  Value is ignored by fog-aliyun
    # [1]: https://github.com/fog/fog-aws/blob/daa50bb3717a462baf4d04d0e0cbfc18baacb541/lib/fog/aws/models/storage/file.rb#L152-L159
    def fog_public
      nil
    end

    def delete_migrated_file(migrated_file)
      migrated_file.delete
    end

    def exists?
      file.present?
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

    def store_path(*args)
      if self.object_store == Store::REMOTE
        path = direct_upload_final_path
        path ||= super

        # We allow administrators to create "sub buckets" by setting a prefix.
        # This makes it possible to deploy GitLab with only one object storage
        # bucket. Because the prefix is configuration data we do not want to
        # store it in the uploads table via RecordsUploads. That means that the
        # prefix cannot be part of store_dir. This is why we chose to implement
        # the prefix support here in store_path.
        self.class.with_bucket_prefix(path)
      else
        super
      end
    end

    # Returns all the possible paths for an upload.
    # the `upload.path` is a lookup parameter, and it may change
    # depending on the `store` param.
    def upload_paths(identifier)
      store_dirs.map { |store, path| File.join(path, identifier) }
    end

    def cache!(new_file = sanitized_file)
      # We intercept ::UploadedFile which might be stored on remote storage
      # We use that for "accelerated" uploads, where we store result on remote storage
      if new_file.is_a?(::UploadedFile) && new_file.remote_id.present?
        return cache_remote_file!(new_file.remote_id, new_file.original_filename)
      end

      super
    end

    def store!(new_file = nil)
      # when direct upload is enabled, always store on remote storage
      if self.class.direct_upload_to_object_store?
        self.object_store = Store::REMOTE
      end

      super
    end

    def exclusive_lease_key
      "object_storage_migrate:#{model.class}:#{model.id}"
    end

    override :delete_tmp_file_after_storage
    def delete_tmp_file_after_storage
      # If final path is present then the file is not on temporary location
      # so we don't want carrierwave to delete it.
      return false if direct_upload_final_path.present?

      super
    end

    def retrieve_from_store!(identifier)
      Gitlab::PathTraversal.check_path_traversal!(identifier)

      # We need to force assign the value of @filename so that we will still
      # get the original_filename in cases wherein the file points to a random generated
      # path format. This happens for direct uploaded files to final location.
      #
      # If we don't set @filename value here, the result of uploader.filename (see ObjectStorage#filename) will result
      # to the value of uploader.file.filename which will then contain the random generated path.
      # The `identifier` variable contains the value of the `file` column which is the original_filename.
      #
      # In cases wherein we are not uploading to final location, it is still fine to set the
      # @filename with the `identifier` value because it still contains the original filename from the `file` column,
      # which is what we want in either case.
      @filename = identifier # rubocop: disable Gitlab/ModuleWithInstanceVariables

      super
    end

    private

    def cache_remote_file!(remote_object_id, original_filename)
      if ObjectStorage::PendingDirectUpload.exists?(self.class.storage_location_identifier, remote_object_id) # rubocop:disable CodeReuse/ActiveRecord
        # This is an assumption that a model with matching pending direct upload will have this attribute
        model.write_attribute(direct_upload_final_path_attribute_name, remote_object_id)
        file_path = self.class.with_bucket_prefix(remote_object_id)
      else
        file_path = File.join(TMP_UPLOAD_PATH, remote_object_id)
        file_path = Pathname.new(file_path).cleanpath.to_s
        raise RemoteStoreError, 'Bad file path' unless file_path.start_with?(TMP_UPLOAD_PATH + '/')
      end

      # TODO:
      # This should be changed to make use of `tmp/cache` mechanism
      # instead of using custom upload directory,
      # using tmp/cache makes this implementation way easier than it is today
      CarrierWave::Storage::Fog::File.new(self, storage_for(Store::REMOTE), file_path).tap do |file|
        raise RemoteStoreError, 'Missing file' if check_remote_file_existence_on_upload? && !file.exists?

        # Remote stored file, we force to store on remote storage
        self.object_store = Store::REMOTE

        # TODO:
        # We store file internally and force it to be considered as `cached`
        # This makes CarrierWave to store file in permament location (copy/delete)
        # once this object is saved, but not sooner
        @cache_id = "force-to-use-cache" # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @file = file # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @filename = original_filename # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end

    # this is a hack around CarrierWave. The #migrate method needs to be
    # able to force the current file to the migrated file upon success.
    def file=(file)
      @file = file # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def serialization_column
      self.class.serialization_column(model.class, mounted_as)
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
        raise "Object Storage is not enabled for #{self.class}" unless self.class.object_store_enabled?

        DirectUploadStorage.new(self)
      when Store::LOCAL
        CarrierWave::Storage::File.new(self)
      else
        raise UnknownStoreError
      end
    end

    def with_exclusive_lease
      lease_key = exclusive_lease_key
      uuid = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.hour.to_i).try_obtain
      raise ExclusiveLeaseTaken, lease_key unless uuid

      yield uuid
    ensure
      Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    end

    #
    # Move the file to another store
    #
    #   new_store: Enum (Store::LOCAL, Store::REMOTE)
    #
    def unsafe_migrate!(new_store)
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
    rescue StandardError => e
      # in case of failure delete new file
      new_file.delete unless new_file.nil?
      # revert back to the old file
      self.object_store = from_object_store
      self.file = file_to_delete
      raise e
    end
  end

  def unsafe_use_file
    if file_storage?
      return yield path
    end

    begin
      cache_stored_file!
      yield cache_path
    ensure
      FileUtils.rm_f(cache_path)
      cache_storage.delete_dir!(cache_path(nil))
    end
  end

  def direct_upload_final_path_attribute_name
    "#{mounted_as}_final_path"
  end

  def direct_upload_final_path
    model.try(direct_upload_final_path_attribute_name)
  end
end

ObjectStorage::Concern.include_mod_with('ObjectStorage::Concern')
