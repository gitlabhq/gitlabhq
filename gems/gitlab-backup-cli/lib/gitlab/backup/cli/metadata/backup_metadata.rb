# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Metadata
        # Backup Metadata includes information about the Backup
        class BackupMetadata
          # Metadata version number should always increase when:
          # - field is added
          # - field is removed
          # - field format/type changes
          METADATA_VERSION = 2

          # Metadata filename used when writing or loading from a filesystem location
          METADATA_FILENAME = 'backup_information.json'

          # Metadata file permissions
          METADATA_FILE_MODE = 0o600 # owner: rw, group: none, all: none (-rw-------)

          # List all of the current top level fields along with their expected data
          # type name to specify how to parse and serialize values
          METADATA_SCHEMA = {
            metadata_version: :integer,
            backup_id: :string,
            created_at: :time,
            gitlab_version: :string
          }.freeze

          # Options used by the JSON parser
          JSON_PARSE_OPTIONS = {
            max_nesting: 1,
            allow_nan: false,
            symbolize_names: true
          }.freeze

          # Integer representing the increment of metadata version
          # this data was saved with
          # @return [Integer]
          attr_reader :metadata_version

          # Unique ID for a backup
          # @return [String]
          attr_reader :backup_id

          # Timestamp when the backup was created
          # @return [Time]
          attr_reader :created_at

          # Gitlab Version in which the backup was created
          # @return [String]
          attr_reader :gitlab_version

          def initialize(
            created_at:,
            backup_id:,
            gitlab_version:,
            metadata_version: METADATA_VERSION
          )
            @metadata_version = metadata_version
            @backup_id = backup_id
            @created_at = created_at
            @gitlab_version = gitlab_version
          end

          # Build a new BackupMetadata with defaults
          #
          # @param [String] gitlab_version
          def self.build(gitlab_version:)
            created_at = Time.current
            backup_id = "#{created_at.strftime('%s_%Y_%m_%d_')}#{gitlab_version}"

            new(
              backup_id: backup_id,
              created_at: created_at,
              gitlab_version: gitlab_version
            )
          end

          # Load the metadata from the JSON file stored in the given basepath
          #
          # @param [String|Pathname] basepath
          # @return [Gitlab::Backup::Cli::Metadata::BackupMetadata, nil]
          def self.load!(basepath)
            basepath = Pathname(basepath) unless basepath.is_a? Pathname

            json_file = basepath.join(METADATA_FILENAME)
            json = JSON.parse(File.read(json_file), JSON_PARSE_OPTIONS)
            deserializer = Gitlab::Backup::Cli::Metadata::Deserializer

            parsed_fields = {}
            METADATA_SCHEMA.each do |attribute_name, type|
              stored_value = json[attribute_name]
              parsed_value = deserializer.parse_value(type: type, value: stored_value)

              parsed_fields[attribute_name] = parsed_value
            end

            new(**parsed_fields)
          rescue IOError, Errno::ENOENT => e
            Gitlab::Backup::Cli::Output.error(
              "Failed to load backup information from: #{json_file} (#{e.message})"
            )

            nil
          end

          # Expose the information that will be part of the Metadata JSON file
          def to_hash
            serializer = Gitlab::Backup::Cli::Metadata::Serializer

            METADATA_SCHEMA.each_with_object({}) do |(attribute_name, type), output|
              # fetch attribute value dynamically
              # rubocop:disable GitlabSecurity/PublicSend - we cant use read_attribute here, methods are already limited
              value = public_send(attribute_name)
              # rubocop:enable GitlabSecurity/PublicSend
              serialized_value = serializer.serialize_value(type: type, value: value)

              output[attribute_name] = serialized_value
            end
          end

          # Write the metadata to a JSON file in the given basepath
          #
          # @param [String|Pathname] basepath
          # @return [Boolean] whether successfully wrote to the disk
          def write!(basepath)
            basepath = Pathname(basepath) unless basepath.is_a? Pathname

            json_file = basepath.join(METADATA_FILENAME)
            json = JSON.pretty_generate(to_hash)

            json_file.open(File::RDWR | File::CREAT, METADATA_FILE_MODE) do |file|
              file.write(json)
            end

            true
          rescue IOError, Errno::ENOENT => e
            Gitlab::Backup::Cli::Output.error("Failed to Backup information to: #{json_file} (#{e.message})")

            false
          end
        end
      end
    end
  end
end
