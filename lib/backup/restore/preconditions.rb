# frozen_string_literal: true

module Backup
  module Restore
    # Class that includes backup compatibility verification logic
    #
    # You can either use it as part of the existing backup logic to ensure
    # a restore is performed only in supported GitLab installation versions
    #
    # or standalone to check whether a Backup's version is supported, before
    # trying to restore it
    class Preconditions
      attr_reader :backup_information, :logger

      # Check preconditions before restoring a backup task
      #
      # @param [Struct] backup_information Backup information
      # @param [Gitlab::BackupLogger] logger interface
      def initialize(backup_information:, logger:)
        @backup_information = backup_information
        @logger = logger
      end

      # Ensure Backup version is compatible with current GitLab installation
      #
      # Currently we only allow restoring a Backup in the same GitLab version it was created
      #
      # We do this because restoring from an older version requires migration steps to be executed
      # and the upgrade path is only checked during GitLab's upgrade process
      #
      # Trying to restore a newer backup on an older GitLab installation will always fail
      def ensure_supported_backup_version!
        gitlab_version_mismatch! unless gitlab_backup_same_version?
      end

      # Validate and report whether Backup version is compatible with current GitLab installation
      def validate_backup_version!
        gitlab_backup_same_version? ? gitlab_version_matches! : gitlab_version_mismatch!
      end

      private

      # Check whether backup version matches gitlab installation
      #
      # @return [Boolean] whether they are the same version
      def gitlab_backup_same_version?
        backup_information[:gitlab_version] == Gitlab::VERSION
      end

      # Display a message for when version mismatches and exit 1
      def gitlab_version_mismatch!
        logger.error(<<~HEREDOC)
          GitLab version mismatch:
            Your current GitLab version (#{Gitlab::VERSION}) differs from the GitLab version in the backup!
            Please switch to the following version and try again:
            version: #{backup_information[:gitlab_version]}
        HEREDOC
        logger.error "Hint: git checkout v#{backup_information[:gitlab_version]}"
        exit 1
      end

      # Display a message for when version matches and exit 0
      def gitlab_version_matches!
        logger.info(<<~HEREDOC)
          GitLab version matches:
            Your current GitLab version (#{Gitlab::VERSION}) matches the GitLab version in the backup.
        HEREDOC
        exit 0
      end
    end
  end
end
