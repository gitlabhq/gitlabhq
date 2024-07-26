# frozen_string_literal: true

module Backup
  module Restore
    class Unpack
      FILE_NAME_SUFFIX = '_gitlab_backup.tar'

      attr_reader :backup_id, :backup_path, :manifest_filepath, :options, :logger

      # Unpacks a tar file from a previous or current backup
      #
      # @param [String] backup_id Current or previous backup ID
      # @param [Pathname] backup_path Backup path defined by Gitlab settings
      # @param [Pathname] manifest_filepath Filepath of backup_information.yml
      # @param [Backup::Options] options Backup options
      # @param [Gitlab::BackupLogger] logger interfaces
      def initialize(backup_id:, backup_path:, manifest_filepath:, options:, logger:)
        @backup_id = backup_id
        @backup_path = backup_path
        @manifest_filepath = manifest_filepath
        @options = options
        @logger = logger
      end

      def run!
        if backup_id.blank? && non_tarred_backup?
          logger.info "Non tarred backup found in #{backup_path}, using that"
          return
        end

        Dir.chdir(backup_path) do
          # Checks for existing backups in the backup dir
          if backup_file_list.empty?
            no_backups_output!
          elsif many_backups?
            many_backups_output!
          end

          # Validates if backup file exists
          validate_tar_file_existence!

          # Starts unpack
          start_unpack!
        end
      end

      private

      def tar_file
        @tar_file ||= if backup_id.present?
                        File.basename(backup_id) + FILE_NAME_SUFFIX
                      else
                        backup_file_list.first
                      end
      end

      def backup_file_list
        @backup_file_list ||= Dir.glob("*#{FILE_NAME_SUFFIX}")
      end

      def available_timestamps
        @backup_file_list.map { |item| item.gsub(FILE_NAME_SUFFIX.to_s, "") }
      end

      def non_tarred_backup?
        File.exist?(manifest_filepath)
      end

      def validate_tar_file_existence!
        return if File.exist?(tar_file)

        logger.error "The backup file #{tar_file} does not exist!"
        exit 1
      end

      def many_backups?
        backup_file_list.many? && backup_id.nil?
      end

      def many_backups_output!
        logger.warn 'Found more than one backup:'
        # Print list of available backups
        available_timestamps.each do |available_timestamp|
          logger.warn " #{available_timestamp}"
        end

        if options.incremental?
          logger.info 'Please specify which one you want to create an incremental backup for:'
          logger.info 'rake gitlab:backup:create INCREMENTAL=true PREVIOUS_BACKUP=timestamp_of_backup'
        else
          logger.info 'Please specify which one you want to restore:'
          logger.info 'rake gitlab:backup:restore BACKUP=timestamp_of_backup'
        end

        exit 1
      end

      def no_backups_output!
        logger.error "No backups found in #{backup_path}"
        logger.error "Please make sure that file name ends with #{FILE_NAME_SUFFIX}"

        exit 1
      end

      def start_unpack!
        logger.info Rainbow('Unpacking backup ... ').blue

        if Kernel.system(*%W[tar -xf #{tar_file}])
          logger.info Rainbow('Unpacking backup ... ').blue + Rainbow('done').green
        else
          logger.error Rainbow('Unpacking backup failed').red

          exit 1
        end
      end
    end
  end
end
