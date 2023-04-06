# frozen_string_literal: true

module Backup
  class Manager
    FILE_NAME_SUFFIX = '_gitlab_backup.tar'
    MANIFEST_NAME = 'backup_information.yml'

    # pages used to deploy tmp files to this path
    # if some of these files are still there, we don't need them in the backup
    LEGACY_PAGES_TMP_PATH = '@pages.tmp'

    LIST_ENVS = {
      skipped: 'SKIP',
      repositories_storages: 'REPOSITORIES_STORAGES',
      repositories_paths: 'REPOSITORIES_PATHS'
    }.freeze

    YAML_PERMITTED_CLASSES = [
      ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, Symbol, Time
    ].freeze

    TaskDefinition = Struct.new(
      :enabled, # `true` if the task can be used. Treated as `true` when not specified.
      :human_name, # Name of the task used for logging.
      :destination_path, # Where the task should put its backup file/dir.
      :destination_optional, # `true` if the destination might not exist on a successful backup.
      :cleanup_path, # Path to remove after a successful backup. Uses `destination_path` when not specified.
      :task,
      keyword_init: true
    ) do
      def enabled?
        enabled.nil? || enabled
      end
    end

    attr_reader :progress

    def initialize(progress, definitions: nil)
      @progress = progress
      @incremental = Gitlab::Utils.to_boolean(ENV['INCREMENTAL'], default: false)
      @definitions = definitions
    end

    def create
      unpack(ENV.fetch('PREVIOUS_BACKUP', ENV['BACKUP'])) if incremental?
      run_all_create_tasks

      puts_time "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
           "and are not included in this backup. You will need these files to restore a backup.\n" \
           "Please back them up manually.".color(:red)
      puts_time "Backup #{backup_id} is done."
    end

    def run_create_task(task_name)
      build_backup_information

      definition = definitions[task_name]

      unless definition.enabled?
        puts_time "Dumping #{definition.human_name} ... ".color(:blue) + "[DISABLED]".color(:cyan)
        return
      end

      if skipped?(task_name)
        puts_time "Dumping #{definition.human_name} ... ".color(:blue) + "[SKIPPED]".color(:cyan)
        return
      end

      puts_time "Dumping #{definition.human_name} ... ".color(:blue)
      definition.task.dump(File.join(Gitlab.config.backup.path, definition.destination_path), full_backup_id)
      puts_time "Dumping #{definition.human_name} ... ".color(:blue) + "done".color(:green)

    rescue Backup::DatabaseBackupError, Backup::FileBackupError => e
      puts_time "Dumping #{definition.human_name} failed: #{e.message}".color(:red)
    end

    def restore
      unpack(ENV['BACKUP'])
      run_all_restore_tasks

      puts_time "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
        "and are not included in this backup. You will need to restore these files manually.".color(:red)
      puts_time "Restore task is done."
    end

    def run_restore_task(task_name)
      read_backup_information

      definition = definitions[task_name]

      unless definition.enabled?
        puts_time "Restoring #{definition.human_name} ... ".color(:blue) + "[DISABLED]".color(:cyan)
        return
      end

      puts_time "Restoring #{definition.human_name} ... ".color(:blue)

      warning = definition.task.pre_restore_warning
      if warning.present?
        puts_time warning.color(:red)
        Gitlab::TaskHelpers.ask_to_continue
      end

      definition.task.restore(File.join(Gitlab.config.backup.path, definition.destination_path))

      puts_time "Restoring #{definition.human_name} ... ".color(:blue) + "done".color(:green)

      warning = definition.task.post_restore_warning
      if warning.present?
        puts_time warning.color(:red)
        Gitlab::TaskHelpers.ask_to_continue
      end

    rescue Gitlab::TaskAbortedByUserError
      puts_time "Quitting...".color(:red)
      exit 1
    end

    private

    def definitions
      @definitions ||= build_definitions
    end

    def build_definitions # rubocop:disable Metrics/AbcSize
      {
        'db' => TaskDefinition.new(
          human_name: _('database'),
          destination_path: 'db',
          cleanup_path: 'db',
          task: build_db_task
        ),
        'repositories' => TaskDefinition.new(
          human_name: _('repositories'),
          destination_path: 'repositories',
          destination_optional: true,
          task: build_repositories_task
        ),
        'uploads' => TaskDefinition.new(
          human_name: _('uploads'),
          destination_path: 'uploads.tar.gz',
          task: build_files_task(File.join(Gitlab.config.uploads.storage_path, 'uploads'), excludes: ['tmp'])
        ),
        'builds' => TaskDefinition.new(
          human_name: _('builds'),
          destination_path: 'builds.tar.gz',
          task: build_files_task(Settings.gitlab_ci.builds_path)
        ),
        'artifacts' => TaskDefinition.new(
          human_name: _('artifacts'),
          destination_path: 'artifacts.tar.gz',
          task: build_files_task(JobArtifactUploader.root, excludes: ['tmp'])
        ),
        'pages' => TaskDefinition.new(
          human_name: _('pages'),
          destination_path: 'pages.tar.gz',
          task: build_files_task(Gitlab.config.pages.path, excludes: [LEGACY_PAGES_TMP_PATH])
        ),
        'lfs' => TaskDefinition.new(
          human_name: _('lfs objects'),
          destination_path: 'lfs.tar.gz',
          task: build_files_task(Settings.lfs.storage_path)
        ),
        'terraform_state' => TaskDefinition.new(
          human_name: _('terraform states'),
          destination_path: 'terraform_state.tar.gz',
          task: build_files_task(Settings.terraform_state.storage_path, excludes: ['tmp'])
        ),
        'registry' => TaskDefinition.new(
          enabled: Gitlab.config.registry.enabled,
          human_name: _('container registry images'),
          destination_path: 'registry.tar.gz',
          task: build_files_task(Settings.registry.path)
        ),
        'packages' => TaskDefinition.new(
          human_name: _('packages'),
          destination_path: 'packages.tar.gz',
          task: build_files_task(Settings.packages.storage_path, excludes: ['tmp'])
        )
      }.freeze
    end

    def build_db_task
      force = Gitlab::Utils.to_boolean(ENV['force'], default: false)

      Database.new(progress, force: force)
    end

    def build_repositories_task
      max_concurrency = ENV['GITLAB_BACKUP_MAX_CONCURRENCY'].presence&.to_i
      max_storage_concurrency = ENV['GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY'].presence&.to_i
      strategy = Backup::GitalyBackup.new(progress, incremental: incremental?, max_parallelism: max_concurrency, storage_parallelism: max_storage_concurrency)

      Repositories.new(progress,
                       strategy: strategy,
                       storages: list_env(:repositories_storages),
                       paths: list_env(:repositories_paths)
                      )
    end

    def build_files_task(app_files_dir, excludes: [])
      Files.new(progress, app_files_dir, excludes: excludes)
    end

    def run_all_create_tasks
      if incremental?
        read_backup_information
        verify_backup_version
        update_backup_information
      end

      build_backup_information

      definitions.each_key do |task_name|
        run_create_task(task_name)
      end

      write_backup_information

      unless skipped?('tar')
        pack
        upload
        remove_old
      end

    ensure
      cleanup unless skipped?('tar')
      remove_tmp
    end

    def run_all_restore_tasks
      read_backup_information
      verify_backup_version

      definitions.each_key do |task_name|
        if !skipped?(task_name) && enabled_task?(task_name)
          run_restore_task(task_name)
        end
      end

      Rake::Task['gitlab:shell:setup'].invoke
      Rake::Task['cache:clear'].invoke

    ensure
      cleanup unless skipped?('tar')
      remove_tmp
    end

    def incremental?
      @incremental
    end

    def read_backup_information
      @backup_information ||= YAML.safe_load_file(
        File.join(backup_path, MANIFEST_NAME),
        permitted_classes: YAML_PERMITTED_CLASSES)
    end

    def write_backup_information
      # Make sure there is a connection
      ::Gitlab::Database.database_base_models.each_value do |base_model|
        base_model.connection.reconnect!
      end

      Dir.chdir(backup_path) do
        File.open("#{backup_path}/#{MANIFEST_NAME}", "w+") do |file|
          file << backup_information.to_yaml.gsub(/^---\n/, '')
        end
      end
    end

    def build_backup_information
      @backup_information ||= {
        db_version: ActiveRecord::Migrator.current_version.to_s,
        backup_created_at: Time.current,
        gitlab_version: Gitlab::VERSION,
        tar_version: tar_version,
        installation_type: Gitlab::INSTALLATION_TYPE,
        skipped: ENV['SKIP'],
        repositories_storages: ENV['REPOSITORIES_STORAGES'],
        repositories_paths: ENV['REPOSITORIES_PATHS']
      }
    end

    def update_backup_information
      @backup_information.merge!(
        full_backup_id: full_backup_id,
        db_version: ActiveRecord::Migrator.current_version.to_s,
        backup_created_at: Time.current,
        gitlab_version: Gitlab::VERSION,
        tar_version: tar_version,
        installation_type: Gitlab::INSTALLATION_TYPE,
        skipped: list_env(:skipped).join(','),
        repositories_storages: list_env(:repositories_storages).join(','),
        repositories_paths: list_env(:repositories_paths).join(',')
      )
    end

    def backup_information
      raise Backup::Error, "#{MANIFEST_NAME} not yet loaded" unless @backup_information

      @backup_information
    end

    def pack
      Dir.chdir(backup_path) do
        # create archive
        puts_time "Creating backup archive: #{tar_file} ... ".color(:blue)
        # Set file permissions on open to prevent chmod races.
        tar_system_options = { out: [tar_file, 'w', Gitlab.config.backup.archive_permissions] }
        if Kernel.system('tar', '-cf', '-', *backup_contents, tar_system_options)
          puts_time "Creating backup archive: #{tar_file} ... ".color(:blue) + 'done'.color(:green)
        else
          puts_time "Creating archive #{tar_file} failed".color(:red)
          raise Backup::Error, 'Backup failed'
        end
      end
    end

    def upload
      connection_settings = Gitlab.config.backup.upload.connection
      if connection_settings.blank? || skipped?('remote') || skipped?('tar')
        puts_time "Uploading backup archive to remote storage #{remote_directory} ... ".color(:blue) + "[SKIPPED]".color(:cyan)
        return
      end

      puts_time "Uploading backup archive to remote storage #{remote_directory} ... ".color(:blue)

      directory = connect_to_remote_directory
      upload = directory.files.create(create_attributes)

      if upload
        if upload.respond_to?(:encryption) && upload.encryption
          puts_time "Uploading backup archive to remote storage #{remote_directory} ... ".color(:blue) + "done (encrypted with #{upload.encryption})".color(:green)
        else
          puts_time "Uploading backup archive to remote storage #{remote_directory} ... ".color(:blue) + "done".color(:green)
        end
      else
        puts_time "Uploading backup to #{remote_directory} failed".color(:red)
        raise Backup::Error, 'Backup failed'
      end
    end

    def cleanup
      puts_time "Deleting tar staging files ... ".color(:blue)

      remove_backup_path(MANIFEST_NAME)
      definitions.each do |_, definition|
        remove_backup_path(definition.cleanup_path || definition.destination_path)
      end

      puts_time "Deleting tar staging files ... ".color(:blue) + 'done'.color(:green)
    end

    def remove_backup_path(path)
      absolute_path = File.join(backup_path, path)
      return unless File.exist?(absolute_path)

      puts_time "Cleaning up #{absolute_path}"
      FileUtils.rm_rf(absolute_path)
    end

    def remove_tmp
      # delete tmp inside backups
      puts_time "Deleting backups/tmp ... ".color(:blue)

      FileUtils.rm_rf(File.join(backup_path, "tmp"))
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

          if incremental?
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

        if Kernel.system(*%W(tar -xf #{tar_file}))
          puts_time 'Unpacking backup ... '.color(:blue) + 'done'.color(:green)
        else
          puts_time 'Unpacking backup failed'.color(:red)
          exit 1
        end
      end
    end

    def tar_version
      tar_version, _ = Gitlab::Popen.popen(%w(tar --version))
      tar_version.dup.force_encoding('locale').split("\n").first
    end

    def skipped?(item)
      skipped.include?(item)
    end

    def skipped
      @skipped ||= list_env(:skipped)
    end

    def list_env(name)
      list = ENV.fetch(LIST_ENVS[name], '').split(',')
      list += backup_information[name].split(',') if backup_information[name]
      list.uniq!
      list.compact!
      list
    end

    def enabled_task?(task_name)
      definitions[task_name].enabled?
    end

    def backup_file?(file)
      file.match(/^(\d{10})(?:_\d{4}_\d{2}_\d{2}(_\d+\.\d+\.\d+((-|\.)(pre|rc\d))?(-ee)?)?)?_gitlab_backup\.tar$/)
    end

    def non_tarred_backup?
      File.exist?(File.join(backup_path, MANIFEST_NAME))
    end

    def backup_path
      Gitlab.config.backup.path
    end

    def backup_file_list
      @backup_file_list ||= Dir.glob("*#{FILE_NAME_SUFFIX}")
    end

    def available_timestamps
      @backup_file_list.map { |item| item.gsub("#{FILE_NAME_SUFFIX}", "") }
    end

    def object_storage_config
      @object_storage_config ||= ObjectStorage::Config.new(Gitlab.config.backup.upload)
    end

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

    def remote_directory
      Gitlab.config.backup.upload.remote_directory
    end

    def remote_target
      if ENV['DIRECTORY']
        File.join(ENV['DIRECTORY'], tar_file)
      else
        tar_file
      end
    end

    def backup_contents
      [MANIFEST_NAME] + definitions.reject do |name, definition|
        skipped?(name) || !enabled_task?(name) ||
          (definition.destination_optional && !File.exist?(File.join(backup_path, definition.destination_path)))
      end.values.map(&:destination_path)
    end

    def tar_file
      @tar_file ||= "#{backup_id}#{FILE_NAME_SUFFIX}"
    end

    def full_backup_id
      full_backup_id = backup_information[:full_backup_id]
      full_backup_id ||= File.basename(ENV['PREVIOUS_BACKUP']) if ENV['PREVIOUS_BACKUP'].present?
      full_backup_id ||= backup_id
      full_backup_id
    end

    def backup_id
      if ENV['BACKUP'].present?
        File.basename(ENV['BACKUP'])
      else
        "#{backup_information[:backup_created_at].strftime('%s_%Y_%m_%d_')}#{backup_information[:gitlab_version]}"
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

      # Use customer-managed keys. Also, this preserves
      # backward-compatibility for existing usages of `SSE-S3` that
      # don't set `backup.upload.storage_options.server_side_encryption`
      # to `'AES256'`.
      {
        encryption_key: Gitlab.config.backup.upload.encryption_key,
        encryption: Gitlab.config.backup.upload.encryption
      }
    end

    def google_provider?
      Gitlab.config.backup.upload.connection&.provider&.downcase == 'google'
    end

    def puts_time(msg)
      progress.puts "#{Time.current} -- #{msg}"
      Gitlab::BackupLogger.info(message: "#{Rainbow.uncolor(msg)}")
    end
  end
end

Backup::Manager.prepend_mod
