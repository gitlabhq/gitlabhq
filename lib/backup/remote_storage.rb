# frozen_string_literal: true

module Backup
  class RemoteStorage
    attr_reader :options, :backup_information, :logger

    def initialize(logger:, options:)
      @logger = logger
      @options = options
    end

    def upload(backup_information:)
      @backup_information = backup_information
      connection_settings = Gitlab.config.backup.upload.connection

      if connection_settings.blank? ||
          options.skippable_operations.remote_storage ||
          options.skippable_operations.archive
        logger.info "Uploading backup archive to remote storage #{remote_directory} ... [SKIPPED]"
        return
      end

      logger.info "Uploading backup archive to remote storage #{remote_directory} ... "

      directory = connect_to_remote_directory
      upload = directory.files.create(create_attributes)

      if upload
        if upload.respond_to?(:encryption) && upload.encryption
          logger.info "Uploading backup archive to remote storage #{remote_directory} ... " \
                      "done (encrypted with #{upload.encryption})"
        else
          logger.info "Uploading backup archive to remote storage #{remote_directory} ... done"
        end
      else
        logger.error "Uploading backup to #{remote_directory} failed"
        raise Backup::Error, 'Backup failed'
      end
    end

    def remote_target
      if options.remote_directory
        File.join(options.remote_directory, tar_file)
      else
        tar_file
      end
    end

    def create_attributes
      attrs = {
        key: remote_target,
        body: File.open(File.join(backup_path, tar_file)),
        multipart_chunk_size: Gitlab.config.backup.upload.multipart_chunk_size,
        storage_class: Gitlab.config.backup.upload.storage_class
      }.merge(encryption_attributes)

      # Google bucket-only policies prevent setting an ACL. In any case, by default,
      # all objects are set to the default ACL, which is project-private:
      # https://cloud.google.com/storage/docs/json_api/v1/defaultObjectAccessControls
      attrs[:public] = false unless google_provider?

      attrs
    end

    def encryption_attributes
      return object_storage_config.fog_attributes if object_storage_config.aws_server_side_encryption_enabled?

      # Use customer-managed keys. Also, this preserves backward-compatibility
      # for existing use of Amazon S3-Managed Keys (SSE-S3) that don't set
      # `backup.upload.storage_options.server_side_encryption` to `'AES256'`.
      #
      # AWS supports three different modes for encrypting S3 data:
      #
      # 1. Server-Side Encryption with Amazon S3-Managed Keys (SSE-S3)
      # 2. Server-Side Encryption with Customer Master Keys (CMKs) Stored in AWS
      # Key Management Service (SSE-KMS)
      # 3. Server-Side Encryption with Customer-Provided Keys (SSE-C)
      #
      # Previously, SSE-S3 and SSE-C were supported via the
      # `backup.upload.encryption` and `backup.upload.encryption_key`
      # configuration options.
      #
      # SSE-KMS was previously not supported in backups because there was no way
      # to specify which customer-managed key to use. However, we did support
      # SSE-KMS with consolidated object storage enabled for other CI artifacts,
      # attachments, LFS, etc. Note that SSE-C is NOT supported here.
      #
      # In consolidated object storage, the `storage_options` Hash provides the
      # `server_side_encryption` and `server_side_encryption_kms_key_id`
      # parameters that allow admins to configure SSE-KMS. We reuse this
      # configuration in backups to support SSE-KMS.
      {
        encryption_key: Gitlab.config.backup.upload.encryption_key,
        encryption: Gitlab.config.backup.upload.encryption
      }
    end

    def google_provider?
      Gitlab.config.backup.upload.connection&.provider&.downcase == 'google'
    end

    private

    def connect_to_remote_directory
      connection = ::Fog::Storage.new(object_storage_config.credentials)

      # We only attempt to create the directory for local backups. For AWS
      # and other cloud providers, we cannot guarantee the user will have
      # permission to create the bucket.
      if connection.service == ::Fog::Storage::Local
        connection.directories.create(key: remote_directory)
      else
        connection.directories.new(key: remote_directory)
      end
    end

    # The remote 'directory' to store your backups. For S3, this would be the bucket name.
    # @example Configuration setting the S3 bucket name
    #    remote_directory: 'my.s3.bucket'
    def remote_directory
      Gitlab.config.backup.upload.remote_directory
    end

    def object_storage_config
      @object_storage_config ||= ObjectStorage::Config.new(Gitlab.config.backup.upload)
    end

    # TODO: This is a temporary workaround for bad design in Backup::Manager
    def tar_file
      @tar_file ||= "#{backup_id}#{Backup::Manager::FILE_NAME_SUFFIX}"
    end

    # TODO: This is a temporary workaround for bad design in Backup::Manager
    def backup_id
      # Eventually the backup ID should only be fetched from
      # backup_information, but we must have a fallback so that older backups
      # can still be used.
      if backup_information[:backup_id].present?
        backup_information[:backup_id]
      elsif options.backup_id.present?
        File.basename(options.backup_id)
      else
        "#{backup_information[:backup_created_at].strftime('%s_%Y_%m_%d_')}#{backup_information[:gitlab_version]}"
      end
    end

    # TODO: This is a temporary workaround for bad design in Backup::Manager
    def backup_path
      Pathname(Gitlab.config.backup.path)
    end
  end
end
