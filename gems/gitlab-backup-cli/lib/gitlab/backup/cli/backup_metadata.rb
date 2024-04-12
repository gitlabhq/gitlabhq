# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      class BackupMetadata
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
      end
    end
  end
end
