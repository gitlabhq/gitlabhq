# frozen_string_literal: true

module Backup
  class Manager
    include ::Gitlab::TaskHelpers

    FILE_NAME_SUFFIX = '_gitlab_backup.tar'
    MANIFEST_NAME = 'backup_information.yml'

    # Use the content from stdin instead of an actual filepath (used by tar as input or output)
    USE_STDIN = '-'

    attr_reader :remote_storage, :options, :logger, :progress

    def initialize(progress, backup_tasks: nil)
      @progress = progress
      @backup_tasks = backup_tasks
      @options = Backup::Options.new
      @metadata = Backup::Metadata.new(manifest_filepath)
      @options.extract_from_env! # preserve existing behavior
      @logger = Gitlab::BackupLogger.new(progress)
      @remote_storage = Backup::RemoteStorage.new(logger: logger, options: options)
    end

    # @return [Boolean] whether all tasks succeeded
    def create
      # Deprecation: Using backup_id (ENV['BACKUP']) to specify previous backup was deprecated in 15.0
      previous_backup = options.previous_backup || options.backup_id

      run_unpack(previous_backup) if options.incremental?

      create_all_tasks_result = run_all_create_tasks

      logger.warn "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
           "and are not included in this backup. You will need these files to restore a backup.\n" \
           "Please back them up manually."
      logger.info "Backup #{backup_id} is done."
      create_all_tasks_result
    end

    # @param [Gitlab::Backup::Tasks::Task] task
    # @return [Boolean] whether the task succeeded
    def run_create_task(task)
      build_backup_information

      unless task.enabled?
        logger.info "Dumping #{task.human_name} ... " + "[DISABLED]"
        return true
      end

      if options.skip_task?(task.id)
        logger.info "Dumping #{task.human_name} ... " + "[SKIPPED]"
        return true
      end

      logger.info "Dumping #{task.human_name} ... "
      task.backup!(backup_path, backup_id)
      logger.info "Dumping #{task.human_name} ... " + "done"
      true

    rescue Backup::DatabaseBackupError, Backup::FileBackupError => e
      logger.error "Dumping #{task.human_name} failed: #{e.message}"
      false
    end

    def restore
      run_unpack(options.backup_id)
      run_all_restore_tasks

      logger.warn "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
        "and are not included in this backup. You will need to restore these files manually."
      logger.info "Restore task is done."
    end

    # Verify whether a backup is compatible with current GitLab's version
    def verify!
      run_unpack(options.backup_id)
      read_backup_information

      preconditions = Backup::Restore::Preconditions.new(
        backup_information: backup_information,
        logger: logger
      )

      preconditions.validate_backup_version!
    ensure
      cleanup
    end

    # @param [Gitlab::Backup::Tasks::Task] task
    def run_restore_task(task)
      read_backup_information

      restore_process = Backup::Restore::Process.new(
        backup_id: backup_id,
        backup_task: task,
        backup_path: backup_path,
        logger: logger
      )

      restore_process.execute!
    end

    # Finds a task by id
    #
    # @param [String] task_id
    # @return [Backup::Tasks::Task]
    def find_task(task_id)
      backup_tasks[task_id].tap do |task|
        raise ArgumentError, "Cannot find task with name: #{task_id}" unless task
      end
    end

    private

    # @return [Hash<String, Backup::Tasks::Task>]
    def backup_tasks
      @backup_tasks ||= {
        Backup::Tasks::Database.id => Backup::Tasks::Database.new(progress: progress, options: options),
        Backup::Tasks::Repositories.id => Backup::Tasks::Repositories.new(progress: progress, options: options,
          server_side_callable: -> { backup_information[:repositories_server_side] }),
        Backup::Tasks::Uploads.id => Backup::Tasks::Uploads.new(progress: progress, options: options),
        Backup::Tasks::Builds.id => Backup::Tasks::Builds.new(progress: progress, options: options),
        Backup::Tasks::Artifacts.id => Backup::Tasks::Artifacts.new(progress: progress, options: options),
        Backup::Tasks::Pages.id => Backup::Tasks::Pages.new(progress: progress, options: options),
        Backup::Tasks::Lfs.id => Backup::Tasks::Lfs.new(progress: progress, options: options),
        Backup::Tasks::TerraformState.id => Backup::Tasks::TerraformState.new(progress: progress, options: options),
        Backup::Tasks::Registry.id => Backup::Tasks::Registry.new(progress: progress, options: options),
        Backup::Tasks::Packages.id => Backup::Tasks::Packages.new(progress: progress, options: options),
        Backup::Tasks::CiSecureFiles.id => Backup::Tasks::CiSecureFiles.new(progress: progress, options: options),
        Backup::Tasks::ExternalDiffs.id => Backup::Tasks::ExternalDiffs.new(progress: progress, options: options)
      }.freeze
    end

    def run_all_create_tasks
      if options.incremental?
        read_backup_information
        check_preconditions
        update_backup_information
      end

      build_backup_information

      create_task_result = []
      backup_tasks.each_value { |task| create_task_result << run_create_task(task) }

      write_backup_information

      unless options.skippable_operations.archive
        pack
        upload
        remove_old
      end

      create_task_result.all?
    ensure
      cleanup unless options.skippable_operations.archive
      remove_tmp
    end

    def run_all_restore_tasks
      read_backup_information
      check_preconditions

      backup_tasks.each_value do |task|
        next unless !options.skip_task?(task.id) && task.enabled?

        run_restore_task(task)
      end

      Rake::Task['gitlab:shell:setup'].invoke
      Rake::Task['cache:clear'].invoke
    ensure
      cleanup unless options.skippable_operations.archive
      remove_tmp
    end

    def run_unpack(backup_id)
      Backup::Restore::Unpack.new(
        backup_id: backup_id,
        backup_path: backup_path,
        manifest_filepath: manifest_filepath,
        options: options,
        logger: logger
      ).run!
    end

    def read_backup_information
      @metadata.load!

      options.update_from_backup_information!(backup_information)
    end

    def write_backup_information
      @metadata.save!
    end

    def build_backup_information
      return if @metadata.backup_information

      backup_created_at = Time.current
      backup_id = if options.backup_id.present?
                    File.basename(options.backup_id)
                  else
                    "#{backup_created_at.strftime('%s_%Y_%m_%d_')}#{Gitlab::VERSION}"
                  end

      @metadata.update(
        backup_id: backup_id,
        db_version: ActiveRecord::Migrator.current_version.to_s,
        backup_created_at: backup_created_at,
        gitlab_version: Gitlab::VERSION,
        tar_version: tar_version,
        installation_type: Gitlab::INSTALLATION_TYPE,
        skipped: options.serialize_skippables,
        repositories_storages: options.repositories_storages.join(','),
        repositories_paths: options.repositories_paths.join(','),
        skip_repositories_paths: options.skip_repositories_paths.join(','),
        repositories_server_side: options.repositories_server_side_backup
      )
    end

    def update_backup_information
      backup_created_at = Time.current
      backup_id = if options.backup_id.present?
                    File.basename(options.backup_id)
                  else
                    "#{backup_created_at.strftime('%s_%Y_%m_%d_')}#{Gitlab::VERSION}"
                  end

      @metadata.update(
        backup_id: backup_id,
        full_backup_id: full_backup_id,
        db_version: ActiveRecord::Migrator.current_version.to_s,
        backup_created_at: backup_created_at,
        gitlab_version: Gitlab::VERSION,
        tar_version: tar_version,
        installation_type: Gitlab::INSTALLATION_TYPE,
        skipped: options.serialize_skippables,
        repositories_storages: options.repositories_storages.join(','),
        repositories_paths: options.repositories_paths.join(','),
        skip_repositories_paths: options.skip_repositories_paths.join(',')
      )
    end

    def backup_information
      raise Backup::Error, "#{MANIFEST_NAME} not yet loaded" unless @metadata.backup_information

      @metadata.backup_information
    end

    def pack
      Dir.chdir(backup_path) do
        # create archive
        logger.info "Creating backup archive: #{tar_file} ... "

        tar_utils = ::Gitlab::Backup::Cli::Utils::Tar.new
        tar_command = tar_utils.pack_cmd(
          archive_file: USE_STDIN,
          target_directory: backup_path,
          target: backup_contents)

        # Set file permissions on open to prevent chmod races.
        archive_permissions = Gitlab.config.backup.archive_permissions
        archive_file = [tar_file, 'w', archive_permissions]

        result = tar_command.run_single_pipeline!(output: archive_file)

        if result.status.success?
          logger.info "Creating backup archive: #{tar_file} ... done"
        else
          logger.error "Creating archive #{tar_file} failed"
          raise Backup::Error, 'Backup failed'
        end
      end
    end

    def upload
      remote_storage.upload(backup_information: backup_information)
    end

    def cleanup
      logger.info "Deleting tar staging files ... "

      remove_backup_path(MANIFEST_NAME)
      backup_tasks.each_value do |task|
        remove_backup_path(task.cleanup_path || task.destination_path)
      end

      logger.info "Deleting tar staging files ... done"
    end

    def remove_backup_path(path)
      absolute_path = backup_path.join(path)
      return unless File.exist?(absolute_path)

      logger.info "Cleaning up #{absolute_path}"
      FileUtils.rm_rf(absolute_path)
    end

    def remove_tmp
      # delete tmp inside backups
      logger.info "Deleting backups/tmp ... "

      FileUtils.rm_rf(backup_path.join('tmp'))
      logger.info "Deleting backups/tmp ... " + "done"
    end

    def remove_old
      # delete backups
      keep_time = Gitlab.config.backup.keep_time.to_i

      if keep_time <= 0
        logger.info "Deleting old backups ... [SKIPPED]"
        return
      end

      logger.info "Deleting old backups ... "
      removed = 0

      Dir.chdir(backup_path) do
        backup_file_list.each do |file|
          # For backward compatibility, there are 3 names the backups can have:
          # - 1495527122_gitlab_backup.tar
          # - 1495527068_2017_05_23_gitlab_backup.tar
          # - 1495527097_2017_05_23_9.3.0-pre_gitlab_backup.tar
          matched = backup_file?(file)
          next unless matched

          timestamp = matched[1].to_i

          next unless Time.zone.at(timestamp) < (Time.current - keep_time)

          begin
            FileUtils.rm(file)
            removed += 1
          rescue StandardError => e
            logger.error "Deleting #{file} failed: #{e.message}"
          end
        end
      end

      logger.info "Deleting old backups ... done. (#{removed} removed)"
    end

    def tar_version
      Gitlab::Backup::Cli::Utils::Tar.new.version
    end

    def backup_file?(file)
      file.match(/^(\d{10})(?:_\d{4}_\d{2}_\d{2}(_\d+\.\d+\.\d+((-|\.)(pre|rc\d))?(-ee)?)?)?_gitlab_backup\.tar$/)
    end

    def manifest_filepath
      backup_path.join(MANIFEST_NAME)
    end

    def backup_path
      Pathname(Gitlab.config.backup.path)
    end

    def backup_file_list
      @backup_file_list ||= Dir.glob("*#{FILE_NAME_SUFFIX}")
    end

    def backup_contents
      [MANIFEST_NAME] + backup_tasks.values.reject do |task|
        options.skip_task?(task.id) || # task skipped via CLI option
          !task.enabled? || # task disabled via code/configuration
          (task.destination_optional && !File.exist?(backup_path.join(task.destination_path)))
      end.map(&:destination_path)
    end

    def tar_file
      @tar_file ||= "#{backup_id}#{FILE_NAME_SUFFIX}"
    end

    def full_backup_id
      full_backup_id = backup_information[:full_backup_id]
      full_backup_id ||= File.basename(options.previous_backup) if options.previous_backup.present?
      full_backup_id || backup_id
    end

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

    def check_preconditions
      preconditions = Backup::Restore::Preconditions.new(
        backup_information: backup_information,
        logger: logger
      )

      preconditions.ensure_supported_backup_version!
    end
  end
end

Backup::Manager.prepend_mod
