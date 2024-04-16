# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
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
        METADATA_FILE_MODE = 0o600

        # Unique ID for a backup
        # @return [String]
        attr_reader :backup_id

        # Timestamp when the backup was created
        # @return [Time]
        attr_reader :created_at

        # Gitlab Version in which the backup was created
        # @return [String]
        attr_reader :gitlab_version

        def initialize(created_at:, backup_id:, gitlab_version:)
          @created_at = created_at
          @backup_id = backup_id
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

        # Expose the information that will be part of the Metadata JSON file
        def to_hash
          {
            metadata_version: METADATA_VERSION,
            backup_id: backup_id,
            created_at: created_at.iso8601,
            gitlab_version: gitlab_version
          }
        end

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
