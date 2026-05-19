# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class MetadataFileReader
        COMPRESSED_METADATA_FILENAME = 'metadata.json.gz'
        METADATA_FILENAME = 'metadata.json'
        TMPDIR_SEGMENT = 'offline_imports'
        # TODO: set to the exact release version once the Offline Transfer feature ships.
        # https://gitlab.com/gitlab-org/gitlab/-/work_items/598364
        MIN_SUPPORTED_VERSION = Gitlab::VersionInfo.new(19, 0)

        MetadataParseError = Class.new(StandardError)
        UnsupportedVersionError = Class.new(StandardError)

        def initialize(configuration)
          @configuration = configuration
        end

        def read
          download_from_object_storage
          decompress_metadata_file

          parsed_metadata.tap { |m| validate_source_version!(m[:instance_version]) }
        ensure
          FileUtils.remove_entry(tmpdir_path)
        end

        private

        attr_reader :configuration

        def download_from_object_storage
          object_key = Import::Offline::ObjectKeyBuilder.new(configuration).metadata_object_key

          strategy = Import::Offline::Imports::ObjectStorageFileDownloadStrategy.new(
            offline_configuration: configuration,
            object_key: object_key
          )

          ::BulkImports::FileDownloadService.new(
            tmpdir: tmpdir_path,
            filename: COMPRESSED_METADATA_FILENAME,
            file_download_strategy: strategy
          ).execute
        end

        def decompress_metadata_file
          ::BulkImports::FileDecompressionService.new(
            tmpdir: tmpdir_path,
            filename: COMPRESSED_METADATA_FILENAME
          ).execute
        end

        def tmpdir_path
          @tmpdir_path ||= Dir.mktmpdir(TMPDIR_SEGMENT)
        end

        def validate_source_version!(instance_version)
          version = Gitlab::VersionInfo.parse(instance_version)

          raise UnsupportedVersionError, s_('OfflineTransfer|Invalid source version') unless version.valid?

          return unless version < MIN_SUPPORTED_VERSION

          raise UnsupportedVersionError, format(
            s_("OfflineTransfer|Unsupported GitLab version. The minimum supported version is '%{version}'."),
            version: MIN_SUPPORTED_VERSION
          )
        end

        def parsed_metadata
          result = Gitlab::Json.safe_parse(File.read(File.join(tmpdir_path, METADATA_FILENAME)))
          raise MetadataParseError, "Failed to parse metadata" if result.nil?

          result.symbolize_keys
        rescue JSON::ParserError
          raise MetadataParseError, "Failed to parse metadata"
        end
      end
    end
  end
end
