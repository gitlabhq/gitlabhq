# frozen_string_literal: true

module Backup
  class Manager
    FILE_NAME_SUFFIX = '_gitlab_backup.tar'
    MANIFEST_NAME = 'backup_information.yml'

    # Use the content from stdin instead of an actual filepath (used by tar as input or output)
    USE_STDIN = '-'

    attr_reader :progress, :remote_storage, :options

    def initialize(progress, backup_tasks: nil)
      @progress = progress
      @backup_tasks = backup_tasks
      @options = Backup::Options.new
      @metadata = Backup::Metadata.new(manifest_filepath)
      @options.extract_from_env! # preserve existing behavior
      @remote_storage = Backup::RemoteStorage.new(progress: progress, options: options)
    end

    # @return [Boolean] whether all tasks succeeded
    def create
      # Deprecation: Using backup_id (ENV['BACKUP']) to specify previous backup was deprecated in 15.0
      previous_backup = options.previous_backup || options.backup_id

      unpack(previous_backup) if options.incremental?
      create_all_tasks_result = run_all_create_tasks

      puts_time "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
           "and are not included in this backup. You will need these files to restore a backup.\n" \
           "Please back them up manually.".color(:red)
      puts_time "Backup #{backup_id} is done."
      create_all_tasks_result
    end

    # @param [Gitlab::Backup::Tasks::Task] task
    # @return [Boolean] whether the task succeeded
    def run_create_task(task)
      build_backup_information

      unless task.enabled?
        puts_time "Dumping #{task.human_name} ... ".color(:blue) + "[DISABLED]".color(:cyan)
        return true
      end

      if options.skip_task?(task.id)
        puts_time "Dumping #{task.human_name} ... ".color(:blue) + "[SKIPPED]".color(:cyan)
        return true
      end

      puts_time "Dumping #{task.human_name} ... ".color(:blue)
      task.backup!(backup_path, backup_id)
      puts_time "Dumping #{task.human_name} ... ".color(:blue) + "done".color(:green)
      true

    rescue Backup::DatabaseBackupError, Backup::FileBackupError => e
      puts_time "Dumping #{task.human_name} failed: #{e.message}".color(:red)
      false
    end

    def restore
      unpack(options.backup_id)
      run_all_restore_tasks

      puts_time "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
        "and are not included in this backup. You will need to restore these files manually.".color(:red)
      puts_time "Restore task is done."
    end

    # @param [Gitlab::Backup::Tasks::Task] task
    def run_restore_task(task)
      read_backup_information

      unless task.enabled?
        puts_time "Restoring #{task.human_name} ... ".color(:blue) + "[DISABLED]".color(:cyan)
        return
      end

      puts_time "Restoring #{task.human_name} ... ".color(:blue)

      warning = task.pre_restore_warning
      if warning.present?
        puts_time warning.color(:red)
        Gitlab::TaskHelpers.ask_to_continue
      end

      task.restore!(backup_path, backup_id)

      puts_time "Restoring #{task.human_name} ... ".color(:blue) + "done".color(:green)

      warning = task.post_restore_warning
      if warning.present?
        puts_time warning.color(:red)
        Gitlab::TaskHelpers.ask_to_continue
      end

    rescue Gitlab::TaskAbortedByUserError
      puts_time "Quitting...".color(:red)
      exit 1
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
        Backup::Tasks::CiSecureFiles.id => Backup::Tasks::CiSecureFiles.new(progress: progress, options: options)
      }.freeze
    end

    def run_all_create_tasks
      if options.incremental?
        read_backup_information
        verify_backup_version
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
      verify_backup_version

      backup_tasks.each_value do |task|
        if !options.skip_task?(task.id) && task.enabled?
          run_restore_task(task)
        end
      end

      Rake::Task['gitlab:shell:setup'].invoke
      Rake::Task['cache:clear'].invoke

    ensure
      cleanup unless options.skippable_operations.archive
      remove_tmp
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
        puts_time "Creating backup archive: #{tar_file} ... ".color(:blue)

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
          puts_time "Creating backup archive: #{tar_file} ... ".color(:blue) + 'done'.color(:green)
        else
          puts_time "Creating archive #{tar_file} failed".color(:red)
          raise Backup::Error, 'Backup failed'
        end
      end
    end

    def upload
      remote_storage.upload(backup_information: backup_information)
    end

    def cleanup
      puts_time "Deleting tar staging files ... ".color(:blue)

      remove_backup_path(MANIFEST_NAME)
      backup_tasks.each_value do |task|
        remove_backup_path(task.cleanup_path || task.destination_path)
      end

      puts_time "Deleting tar staging files ... ".color(:blue) + 'done'.color(:green)
    end

    def remove_backup_path(path)
      absolute_path = backup_path.join(path)
      return unless File.exist?(absolute_path)

      puts_time "Cleaning up #{absolute_path}"
      FileUtils.rm_rf(absolute_path)
    end

    def remove_tmp
      # delete tmp inside backups
      puts_time "Deleting backups/tmp ... ".color(:blue)

      FileUtils.rm_rf(backup_path.join('tmp'))
      puts_time "Deleting backups/tmp ... ".color(:blue) + "done".color(:green)
    end

    def remove_old
      # delete backups
      keep_time = Gitlab.config.backup.keep_time.to_i

      if keep_time <= 0
        puts_time "Deleting old backups ... ".color(:blue) + "[SKIPPED]".color(:cyan)
        return
      end

      puts_time "Deleting old backups ... ".color(:blue)
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
            puts_time "Deleting #{file} failed: #{e.message}".color(:red)
          end
        end
      end

      puts_time "Deleting old backups ... ".color(:blue) + "done. (#{removed} removed)".color(:green)
    end

    def verify_backup_version
      Dir.chdir(backup_path) do
        # restoring mismatching backups can lead to unexpected problems
        if backup_information[:gitlab_version] != Gitlab::VERSION
          progress.puts(<<~HEREDOC.color(:red))
            GitLab version mismatch:
              Your current GitLab version (#{Gitlab::VERSION}) differs from the GitLab version in the backup!
              Please switch to the following version and try again:
              version: #{backup_information[:gitlab_version]}
          HEREDOC
          progress.puts
          progress.puts "Hint: git checkout v#{backup_information[:gitlab_version]}"
          exit 1
        end
      end
    end

    def puts_available_timestamps
      available_timestamps.each do |available_timestamp|
        puts_time " " + available_timestamp
      end
    end

    def unpack(source_backup_id)
      if source_backup_id.blank? && non_tarred_backup?
        puts_time "Non tarred backup found in #{backup_path}, using that"
        return
      end

      Dir.chdir(backup_path) do
        # check for existing backups in the backup dir
        if backup_file_list.empty?
          puts_time "No backups found in #{backup_path}"
          puts_time "Please make sure that file name ends with #{FILE_NAME_SUFFIX}"
          exit 1
        elsif backup_file_list.many? && source_backup_id.nil?
          puts_time 'Found more than one backup:'
          # print list of available backups
          puts_available_timestamps

          if options.incremental?
            puts_time 'Please specify which one you want to create an incremental backup for:'
            puts_time 'rake gitlab:backup:create INCREMENTAL=true PREVIOUS_BACKUP=timestamp_of_backup'
          else
            puts_time 'Please specify which one you want to restore:'
            puts_time 'rake gitlab:backup:restore BACKUP=timestamp_of_backup'
          end

          exit 1
        end

        tar_file = if source_backup_id.present?
                     File.basename(source_backup_id) + FILE_NAME_SUFFIX
                   else
                     backup_file_list.first
                   end

        unless File.exist?(tar_file)
          puts_time "The backup file #{tar_file} does not exist!"
          exit 1
        end

        puts_time 'Unpacking backup ... '.color(:blue)

        if Kernel.system(*%W[tar -xf #{tar_file}])
          puts_time 'Unpacking backup ... '.color(:blue) + 'done'.color(:green)
        else
          puts_time 'Unpacking backup failed'.color(:red)
          exit 1
        end
      end
    end

    def tar_version
      Gitlab::Backup::Cli::Utils::Tar.new.version
    end

    def backup_file?(file)
      file.match(/^(\d{10})(?:_\d{4}_\d{2}_\d{2}(_\d+\.\d+\.\d+((-|\.)(pre|rc\d))?(-ee)?)?)?_gitlab_backup\.tar$/)
    end

    def non_tarred_backup?
      File.exist?(manifest_filepath)
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

    def available_timestamps
      @backup_file_list.map { |item| item.gsub("#{FILE_NAME_SUFFIX}", "") }
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
      full_backup_id ||= backup_id
      full_backup_id
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

    def puts_time(msg)
      progress.puts "#{Time.current} -- #{msg}"
      Gitlab::BackupLogger.info(message: "#{Rainbow.uncolor(msg)}")
    end
  end
end

Backup::Manager.prepend_mod
