# frozen_string_literal: true

module Backup
  # Backup options provided by the command line interface
  class Options
    # SkippableTasks store which tasks can be skipped
    # Setting any one to true, will create or restore a backup without that data
    # @example Skipping database content and CI job artifacts
    #    SkippableTasks.new(db: true, artifacts: true)
    SkippableTasks = Struct.new(
      :db, # Database content (PostgreSQL)
      :uploads, # Attachments
      :builds, # CI job output logs
      :artifacts, # CI job artifacts
      :lfs, # LFS objects
      :terraform_state, # Terraform states
      :registry, # Container registry images
      :pages, # GitLab Pages content
      :repositories, # Repositories
      :packages, # Packages
      :ci_secure_files, # Project-level Secure Files
      :external_diffs, # External Merge Request diffs
      keyword_init: true
    )

    # What operations can be skipped
    SkippableOperations = Struct.new(
      :archive, # whether to skip .tar step
      :remote_storage, # whether to skip uploading to remote storage
      keyword_init: true
    )

    CompressionOptions = Struct.new(
      :compression_cmd, # custom compression command
      :decompression_cmd, # custom decompression command
      keyword_init: true
    )

    # A backup will by default use STREAM strategy where content is streamed to the archive
    # With COPY strategy, files are copied first to a temporary location before they are added to the archive
    module Strategy
      STREAM = :stream
      COPY = :copy
    end

    # Backup ID is the backup filename portion without extensions
    # When this option is not provided, the backup name will be based on date, timestamp and gitlab version
    #
    # @return [String|Nil] backup id that is used as part of filename
    attr_accessor :backup_id

    # Reference to previous backup full path
    #
    # @return [String|Nil] previous backup full path
    attr_accessor :previous_backup

    # Run incremental backup?
    #
    # @return [Boolean] whether to run an incremental backup
    attr_accessor :incremental
    alias_method :incremental?, :incremental

    # Whether to bypass warnings when performing dangerous operations
    # This is currently being used for the database restore task only
    #
    # @return [Boolean] whether to bypass warnings and perform dangerous operations
    attr_accessor :force
    alias_method :force?, :force

    # What strategy the backup process should use
    #
    # @return [Strategy::STREAM|Strategy::COPY]
    attr_accessor :strategy

    # A list of all tasks and whether they can be skipped or not
    #
    # @return [SkippableTasks]
    attr_accessor :skippable_tasks

    # A list of all operations and whether they can be skipped or not
    #
    # @return [SkippableOperations]
    attr_accessor :skippable_operations

    # When using multiple repository storages, repositories can be backed up and restored in parallel
    # This option allows to customize the overall limit.
    #
    # This is only used by repository backup and restore steps (GitalyBackup)
    #
    # @return [Integer|Nil] limit of backup or restore operations to happen in parallel overall
    attr_accessor :max_parallelism

    # When using multiple repository storages, repositories can be backed up and restored in parallel
    # This option allows to customize the limit per storage.
    #
    # This is only used by repository backup and restore steps (GitalyBackup)
    #
    # @return [Integer|Nil] limit of backup or restore operations to happen in parallel per storage
    attr_accessor :max_storage_parallelism

    # When using multiple repository storages, repositories from specific storages can be backed up
    # separately by running the backup operation while setting this option
    #
    # @return [Array<String>] a list of repository storages to be backed up
    attr_accessor :repositories_storages

    # In order to backup specific repositories, multiple paths containing the
    # selected namespaces will be used to find which repositories to backup
    #
    # Ex: ['group-a', 'group-b/project-c'] will select all projects in group-a and project-c in group-b
    # This can be combined with #skip_repositories_paths
    #
    # @return [Array<String>] a list of paths to select which repositories to backup
    attr_accessor :repositories_paths

    # In order to backup specific repositories, multiple paths containing the
    # selected namespaces can be specified using #repositories_paths. To further
    # refine the list, a new list of paths can be provided to be skipped among
    # the previous pre-selected ones.
    #
    # Ex: for a repository_paths containing ['group-a'] and skip_repository_paths
    # containing ['group-a/project-d'], all projects in `group-a` except `project-d`
    # will be backed up
    #
    # @return [Array<String>] a list of paths to skip backup
    attr_accessor :skip_repositories_paths

    # Specify GitalyBackup to handle and perform backups server-side and stream it to object storage
    #
    # When this is defined, repositories will not be part of the backup archive
    # @return [Boolean] whether to perform server-side backups for repositories
    attr_accessor :repositories_server_side_backup

    # A custom directory to send your remote backups to
    # It can be used to group different types of backups (ex: daily, weekly)
    #
    # @return [String|Nil]
    attr_accessor :remote_directory

    # Custom compression and decompression options
    #
    # When compression is customized, it will ignore other related options like `:gzip_rsyncable`
    # @return [CompressionOptions] custom compression and decompression commands
    attr_accessor :compression_options

    # Whether to run gzip with `--rsyncable` flag
    #
    # This is ignored if custom :compression_options are provided
    # @return [Boolean] whether to use `--rsyncable` flag with gzip
    attr_accessor :gzip_rsyncable

    # If the container registry is using object storage, this is the bucket that is used
    # @return [String|Nil]
    attr_accessor :container_registry_bucket

    # If we are backing up object storage in GCP, this is a file containing the service account credentials to use
    attr_accessor :service_account_file

    # rubocop:disable Metrics/ParameterLists -- This is a data object with all possible CMD options
    def initialize(
      backup_id: nil, previous_backup: nil, incremental: false, force: false, strategy: Strategy::STREAM,
      skippable_tasks: SkippableTasks.new, skippable_operations: SkippableOperations.new,
      max_parallelism: nil, max_storage_parallelism: nil,
      repository_storages: [], repository_paths: [], skip_repository_paths: [],
      repositories_server_side_backup: false, remote_directory: nil,
      compression_options: CompressionOptions.new, gzip_rsyncable: false, container_registry_bucket: nil,
      service_account_file: nil)
      @backup_id = backup_id
      @previous_backup = previous_backup
      @incremental = incremental
      @force = force
      @strategy = strategy
      @skippable_tasks = skippable_tasks
      @skippable_operations = skippable_operations
      @max_parallelism = max_parallelism
      @max_storage_parallelism = max_storage_parallelism
      @remote_directory = remote_directory
      @repositories_server_side_backup = repositories_server_side_backup
      @repositories_storages = repository_storages
      @repositories_paths = repository_paths
      @skip_repositories_paths = skip_repository_paths
      @compression_options = compression_options
      @gzip_rsyncable = gzip_rsyncable
      @container_registry_bucket = container_registry_bucket
      @service_account_file = service_account_file
    end
    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/AbcSize -- TODO: Complexity will be solved in the Unified Backup implementation (https://gitlab.com/groups/gitlab-org/-/epics/11635)
    # Extract supported options from defined ENV variables
    def extract_from_env!
      # We've used lowercase `force` as the key while ENV normally is defined using UPPERCASE letters
      # This provides a fallback when the user defines using expected standards, while not breaking compatibility
      force_value = ENV.key?('FORCE') ? ENV['FORCE'] : ENV['force']

      self.backup_id = ENV['BACKUP']
      self.previous_backup = ENV['PREVIOUS_BACKUP']
      self.incremental = Gitlab::Utils.to_boolean(ENV['INCREMENTAL'], default: incremental)
      self.force = Gitlab::Utils.to_boolean(force_value, default: force)
      self.strategy = Strategy::COPY if ENV['STRATEGY'] == 'copy'
      self.max_parallelism = ENV['GITLAB_BACKUP_MAX_CONCURRENCY']&.to_i
      self.max_storage_parallelism = ENV['GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY']&.to_i
      self.remote_directory = ENV['DIRECTORY']
      self.repositories_server_side_backup = Gitlab::Utils.to_boolean(ENV['REPOSITORIES_SERVER_SIDE'],
        default: repositories_server_side_backup)
      self.repositories_storages = ENV.fetch('REPOSITORIES_STORAGES', '').split(',').uniq
      self.repositories_paths = ENV.fetch('REPOSITORIES_PATHS', '').split(',').uniq
      self.skip_repositories_paths = ENV.fetch('SKIP_REPOSITORIES_PATHS', '').split(',').uniq
      compression_options.compression_cmd = ENV['COMPRESS_CMD']
      compression_options.decompression_cmd = ENV['DECOMPRESS_CMD']
      self.gzip_rsyncable = Gitlab::Utils.to_boolean(ENV['GZIP_RSYNCABLE'], default: gzip_rsyncable)

      extract_skippables!(ENV['SKIP']) if ENV['SKIP'].present?
    end
    # rubocop:enable Metrics/AbcSize

    def update_from_backup_information!(backup_information)
      self.repositories_storages += backup_information[:repositories_storages]&.split(',') || []
      self.repositories_storages.uniq!
      self.repositories_storages.compact!

      self.repositories_paths += backup_information[:repositories_paths]&.split(',') || []
      self.repositories_paths.uniq!
      self.repositories_paths.compact!

      self.skip_repositories_paths += backup_information[:skip_repositories_paths]&.split(',') || []
      self.skip_repositories_paths.uniq!
      self.skip_repositories_paths.compact!

      extract_skippables!(backup_information[:skipped]) if backup_information[:skipped]
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity -- TODO: Complexity will be solved in the Unified Backup implementation (https://gitlab.com/groups/gitlab-org/-/epics/11635)
    # Return a String with a list of skippables, separated by commas
    #
    # @return [String] a list of skippables
    def serialize_skippables
      list = []
      list << 'tar' if skippable_operations.archive
      list << 'remote' if skippable_operations.remote_storage
      list << 'db' if skippable_tasks.db
      list << 'uploads' if skippable_tasks.uploads
      list << 'builds' if skippable_tasks.builds
      list << 'artifacts' if skippable_tasks.artifacts
      list << 'lfs' if skippable_tasks.lfs
      list << 'terraform_state' if skippable_tasks.terraform_state
      list << 'registry' if skippable_tasks.registry
      list << 'pages' if skippable_tasks.pages
      list << 'repositories' if skippable_tasks.repositories
      list << 'packages' if skippable_tasks.packages
      list << 'ci_secure_files' if skippable_tasks.ci_secure_files
      list << 'external_diffs' if skippable_tasks.external_diffs
      list.join(',')
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Extract skippables from provided data field
    # Current callers will provide either ENV['SKIP'] or backup_information[:skipped] content
    #
    # The first time the method is executed it will setup `true` or `false` to each field
    # subsequent executions will preserve `true` values and evaluate again only when previously set to `false`
    #
    # @param [String] field contains a list separated by comma without surrounding spaces
    def extract_skippables!(field)
      list = field.split(',').uniq

      extract_skippable_operations!(list)
      extract_skippable_tasks(list)
    end

    def skip_task?(task_name)
      !!skippable_tasks[task_name]
    end

    private

    def extract_skippable_operations!(list)
      skippable_operations.archive ||= list.include?('tar') # SKIP=tar
      skippable_operations.remote_storage ||= list.include?('remote') # SKIP=remote
    end

    def extract_skippable_tasks(list)
      skippable_tasks.db ||= list.include?('db') # SKIP=db
      skippable_tasks.uploads ||= list.include?('uploads') # SKIP=uploads
      skippable_tasks.builds ||= list.include?('builds') # SKIP=builds
      skippable_tasks.artifacts ||= list.include?('artifacts') # SKIP=artifacts
      skippable_tasks.lfs ||= list.include?('lfs') # SKIP=lfs
      skippable_tasks.terraform_state ||= list.include?('terraform_state') # SKIP=terraform_state
      skippable_tasks.registry ||= list.include?('registry') # SKIP=registry
      skippable_tasks.pages ||= list.include?('pages') # SKIP=pages
      skippable_tasks.repositories ||= list.include?('repositories') # SKIP=repositories
      skippable_tasks.packages ||= list.include?('packages') # SKIP=packages
      skippable_tasks.ci_secure_files ||= list.include?('ci_secure_files') # SKIP=ci_secure_files
      skippable_tasks.external_diffs ||= list.include?('external_diffs') # SKIP=external_diffs
    end
  end
end
