# Gitaly note: JV: two sets of straightforward RPC's. 1 Hard RPC: fork_repository.
# SSH key operations are not part of Gitaly so will never be migrated.

require 'securerandom'

module Gitlab
  class Shell
    GITLAB_SHELL_ENV_VARS = %w(GIT_TERMINAL_PROMPT).freeze

    Error = Class.new(StandardError)

    KeyAdder = Struct.new(:io) do
      def add_key(id, key)
        key = Gitlab::Shell.strip_key(key)
        # Newline and tab are part of the 'protocol' used to transmit id+key to the other end
        if key.include?("\t") || key.include?("\n")
          raise Error.new("Invalid key: #{key.inspect}")
        end

        io.puts("#{id}\t#{key}")
      end
    end

    class << self
      def secret_token
        @secret_token ||= begin
          File.read(Gitlab.config.gitlab_shell.secret_file).chomp
        end
      end

      def ensure_secret_token!
        return if File.exist?(File.join(Gitlab.config.gitlab_shell.path, '.gitlab_shell_secret'))

        generate_and_link_secret_token
      end

      def version_required
        @version_required ||= File.read(Rails.root
                                        .join('GITLAB_SHELL_VERSION')).strip
      end

      def strip_key(key)
        key.split(/[ ]+/)[0, 2].join(' ')
      end

      private

      # Create (if necessary) and link the secret token file
      def generate_and_link_secret_token
        secret_file = Gitlab.config.gitlab_shell.secret_file
        shell_path = Gitlab.config.gitlab_shell.path

        unless File.size?(secret_file)
          # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
          @secret_token = SecureRandom.hex(16)
          File.write(secret_file, @secret_token)
        end

        link_path = File.join(shell_path, '.gitlab_shell_secret')
        if File.exist?(shell_path) && !File.exist?(link_path)
          FileUtils.symlink(secret_file, link_path)
        end
      end
    end

    # Init new repository
    #
    # storage - project's storage name
    # name - project disk path
    #
    # Ex.
    #   add_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    def add_repository(storage, name)
      relative_path = name.dup
      relative_path << '.git' unless relative_path.end_with?('.git')

      gitaly_migrate(:create_repository) do |is_enabled|
        if is_enabled
          repository = Gitlab::Git::Repository.new(storage, relative_path, '')
          repository.gitaly_repository_client.create_repository
          true
        else
          repo_path = File.join(Gitlab.config.repositories.storages[storage].legacy_disk_path, relative_path)
          Gitlab::Git::Repository.create(repo_path, bare: true, symlink_hooks_to: gitlab_shell_hooks_path)
        end
      end
    rescue => err
      Rails.logger.error("Failed to add repository #{storage}/#{name}: #{err}")
      false
    end

    # Import repository
    #
    # storage - project's storage path
    # name - project disk path
    # url - URL to import from
    #
    # Ex.
    #   import_repository("/path/to/storage", "gitlab/gitlab-ci", "https://gitlab.com/gitlab-org/gitlab-test.git")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/874
    def import_repository(storage, name, url)
      if url.start_with?('.', '/')
        raise Error.new("don't use disk paths with import_repository: #{url.inspect}")
      end

      # The timeout ensures the subprocess won't hang forever
      cmd = gitlab_projects(storage, "#{name}.git")
      success = cmd.import_project(url, git_timeout)

      raise Error, cmd.output unless success

      success
    end

    # Fetch remote for repository
    #
    # repository - an instance of Git::Repository
    # remote - remote name
    # ssh_auth - SSH known_hosts data and a private key to use for public-key authentication
    # forced - should we use --force flag?
    # no_tags - should we use --no-tags flag?
    #
    # Ex.
    #   fetch_remote(my_repo, "upstream")
    #
    def fetch_remote(repository, remote, ssh_auth: nil, forced: false, no_tags: false, prune: true)
      gitaly_migrate(:fetch_remote) do |is_enabled|
        if is_enabled
          repository.gitaly_repository_client.fetch_remote(remote, ssh_auth: ssh_auth, forced: forced, no_tags: no_tags, timeout: git_timeout, prune: prune)
        else
          storage_path = Gitlab.config.repositories.storages[repository.storage].legacy_disk_path
          local_fetch_remote(storage_path, repository.relative_path, remote, ssh_auth: ssh_auth, forced: forced, no_tags: no_tags, prune: prune)
        end
      end
    end

    # Move repository reroutes to mv_directory which is an alias for
    # mv_namespace. Given the underlying implementation is a move action,
    # indescriminate of what the folders might be.
    #
    # storage - project's storage path
    # path - project disk path
    # new_path - new project disk path
    #
    # Ex.
    #   mv_repository("/path/to/storage", "gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/873
    def mv_repository(storage, path, new_path)
      return false if path.empty? || new_path.empty?

      !!mv_directory(storage, "#{path}.git", "#{new_path}.git")
    end

    # Fork repository to new path
    # forked_from_storage - forked-from project's storage path
    # forked_from_disk_path - project disk path
    # forked_to_storage - forked-to project's storage path
    # forked_to_disk_path - forked project disk path
    #
    # Ex.
    #  fork_repository("/path/to/forked_from/storage", "gitlab/gitlab-ci", "/path/to/forked_to/storage", "new-namespace/gitlab-ci")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/817
    def fork_repository(forked_from_storage, forked_from_disk_path, forked_to_storage, forked_to_disk_path)
      gitlab_projects(forked_from_storage, "#{forked_from_disk_path}.git")
        .fork_repository(forked_to_storage, "#{forked_to_disk_path}.git")
    end

    # Removes a repository from file system, using rm_diretory which is an alias
    # for rm_namespace. Given the underlying implementation removes the name
    # passed as second argument on the passed storage.
    #
    # storage - project's storage path
    # name - project disk path
    #
    # Ex.
    #   remove_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/873
    def remove_repository(storage, name)
      return false if name.empty?

      !!rm_directory(storage, "#{name}.git")
    rescue ArgumentError => e
      Rails.logger.warn("Repository does not exist: #{e} at: #{name}.git")
      false
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("key-42", "sha-rsa ...")
    #
    def add_key(key_id, key_content)
      return unless self.authorized_keys_enabled?

      gitlab_shell_fast_execute([gitlab_shell_keys_path,
                                 'add-key', key_id, self.class.strip_key(key_content)])
    end

    # Batch-add keys to authorized_keys
    #
    # Ex.
    #   batch_add_keys { |adder| adder.add_key("key-42", "sha-rsa ...") }
    def batch_add_keys(&block)
      return unless self.authorized_keys_enabled?

      IO.popen(%W(#{gitlab_shell_path}/bin/gitlab-keys batch-add-keys), 'w') do |io|
        yield(KeyAdder.new(io))
      end
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("key-342", "sha-rsa ...")
    #
    def remove_key(key_id, key_content = nil)
      return unless self.authorized_keys_enabled?

      args = [gitlab_shell_keys_path, 'rm-key', key_id]
      args << key_content if key_content
      gitlab_shell_fast_execute(args)
    end

    # Remove all ssh keys from gitlab shell
    #
    # Ex.
    #   remove_all_keys
    #
    def remove_all_keys
      return unless self.authorized_keys_enabled?

      gitlab_shell_fast_execute([gitlab_shell_keys_path, 'clear'])
    end

    # Remove ssh keys from gitlab shell that are not in the DB
    #
    # Ex.
    #   remove_keys_not_found_in_db
    #
    def remove_keys_not_found_in_db
      return unless self.authorized_keys_enabled?

      Rails.logger.info("Removing keys not found in DB")

      batch_read_key_ids do |ids_in_file|
        ids_in_file.uniq!
        keys_in_db = Key.where(id: ids_in_file)

        next unless ids_in_file.size > keys_in_db.count # optimization

        ids_to_remove = ids_in_file - keys_in_db.pluck(:id)
        ids_to_remove.each do |id|
          Rails.logger.info("Removing key-#{id} not found in DB")
          remove_key("key-#{id}")
        end
      end
    end

    # Iterate over all ssh key IDs from gitlab shell, in batches
    #
    # Ex.
    #   batch_read_key_ids { |batch| keys = Key.where(id: batch) }
    #
    def batch_read_key_ids(batch_size: 100, &block)
      return unless self.authorized_keys_enabled?

      list_key_ids do |key_id_stream|
        key_id_stream.lazy.each_slice(batch_size) do |lines|
          key_ids = lines.map { |l| l.chomp.to_i }
          yield(key_ids)
        end
      end
    end

    # Stream all ssh key IDs from gitlab shell, separated by newlines
    #
    # Ex.
    #   list_key_ids
    #
    def list_key_ids(&block)
      return unless self.authorized_keys_enabled?

      IO.popen(%W(#{gitlab_shell_path}/bin/gitlab-keys list-key-ids), &block)
    end

    # Add empty directory for storing repositories
    #
    # Ex.
    #   add_namespace("/path/to/storage", "gitlab")
    #
    def add_namespace(storage, name)
      Gitlab::GitalyClient.migrate(:add_namespace,
                                   status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |enabled|
        if enabled
          gitaly_namespace_client(storage).add(name)
        else
          path = full_path(storage, name)
          FileUtils.mkdir_p(path, mode: 0770) unless exists?(storage, name)
        end
      end
    rescue Errno::EEXIST => e
      Rails.logger.warn("Directory exists as a file: #{e} at: #{path}")
    rescue GRPC::InvalidArgument => e
      raise ArgumentError, e.message
    end

    # Remove directory from repositories storage
    # Every repository inside this directory will be removed too
    #
    # Ex.
    #   rm_namespace("/path/to/storage", "gitlab")
    #
    def rm_namespace(storage, name)
      Gitlab::GitalyClient.migrate(:remove_namespace,
                               status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |enabled|
        if enabled
          gitaly_namespace_client(storage).remove(name)
        else
          FileUtils.rm_r(full_path(storage, name), force: true)
        end
      end
    rescue GRPC::InvalidArgument => e
      raise ArgumentError, e.message
    end
    alias_method :rm_directory, :rm_namespace

    # Move namespace directory inside repositories storage
    #
    # Ex.
    #   mv_namespace("/path/to/storage", "gitlab", "gitlabhq")
    #
    def mv_namespace(storage, old_name, new_name)
      Gitlab::GitalyClient.migrate(:rename_namespace,
                                   status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |enabled|
        if enabled
          gitaly_namespace_client(storage).rename(old_name, new_name)
        else
          return false if exists?(storage, new_name) || !exists?(storage, old_name)

          FileUtils.mv(full_path(storage, old_name), full_path(storage, new_name))
        end
      end
    rescue GRPC::InvalidArgument
      false
    end
    alias_method :mv_directory, :mv_namespace

    def url_to_repo(path)
      Gitlab.config.gitlab_shell.ssh_path_prefix + "#{path}.git"
    end

    # Return GitLab shell version
    def version
      gitlab_shell_version_file = "#{gitlab_shell_path}/VERSION"

      if File.readable?(gitlab_shell_version_file)
        File.read(gitlab_shell_version_file).chomp
      end
    end

    # Check if such directory exists in repositories.
    #
    # Usage:
    #   exists?(storage, 'gitlab')
    #   exists?(storage, 'gitlab/cookies.git')
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def exists?(storage, dir_name)
      Gitlab::GitalyClient.migrate(:namespace_exists,
                                   status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |enabled|
        if enabled
          gitaly_namespace_client(storage).exists?(dir_name)
        else
          File.exist?(full_path(storage, dir_name))
        end
      end
    end

    protected

    def gitlab_shell_path
      File.expand_path(Gitlab.config.gitlab_shell.path)
    end

    def gitlab_shell_hooks_path
      File.expand_path(Gitlab.config.gitlab_shell.hooks_path)
    end

    def gitlab_shell_user_home
      File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
    end

    def full_path(storage, dir_name)
      raise ArgumentError.new("Directory name can't be blank") if dir_name.blank?

      File.join(storage, dir_name)
    end

    def gitlab_shell_projects_path
      File.join(gitlab_shell_path, 'bin', 'gitlab-projects')
    end

    def gitlab_shell_keys_path
      File.join(gitlab_shell_path, 'bin', 'gitlab-keys')
    end

    def authorized_keys_enabled?
      # Return true if nil to ensure the authorized_keys methods work while
      # fixing the authorized_keys file during migration.
      return true if Gitlab::CurrentSettings.current_application_settings.authorized_keys_enabled.nil?

      Gitlab::CurrentSettings.current_application_settings.authorized_keys_enabled
    end

    private

    def gitlab_projects(shard_path, disk_path)
      Gitlab::Git::GitlabProjects.new(
        shard_path,
        disk_path,
        global_hooks_path: Gitlab.config.gitlab_shell.hooks_path,
        logger: Rails.logger
      )
    end

    def local_fetch_remote(storage_path, repository_relative_path, remote, ssh_auth: nil, forced: false, no_tags: false, prune: true)
      vars = { force: forced, tags: !no_tags, prune: prune }

      if ssh_auth&.ssh_import?
        if ssh_auth.ssh_key_auth? && ssh_auth.ssh_private_key.present?
          vars[:ssh_key] = ssh_auth.ssh_private_key
        end

        if ssh_auth.ssh_known_hosts.present?
          vars[:known_hosts] = ssh_auth.ssh_known_hosts
        end
      end

      cmd = gitlab_projects(storage_path, repository_relative_path)

      success = cmd.fetch_remote(remote, git_timeout, vars)

      raise Error, cmd.output unless success

      success
    end

    def gitlab_shell_fast_execute(cmd)
      output, status = gitlab_shell_fast_execute_helper(cmd)

      return true if status.zero?

      Rails.logger.error("gitlab-shell failed with error #{status}: #{output}")
      false
    end

    def gitlab_shell_fast_execute_raise_error(cmd, vars = {})
      output, status = gitlab_shell_fast_execute_helper(cmd, vars)

      raise Error, output unless status.zero?

      true
    end

    def gitlab_shell_fast_execute_helper(cmd, vars = {})
      vars.merge!(ENV.to_h.slice(*GITLAB_SHELL_ENV_VARS))

      # Don't pass along the entire parent environment to prevent gitlab-shell
      # from wasting I/O by searching through GEM_PATH
      Bundler.with_original_env { Popen.popen(cmd, nil, vars) }
    end

    def gitaly_namespace_client(storage_path)
      storage, _value = Gitlab.config.repositories.storages.find do |storage, value|
        value.legacy_disk_path == storage_path
      end

      Gitlab::GitalyClient::NamespaceService.new(storage)
    end

    def git_timeout
      Gitlab.config.gitlab_shell.git_timeout
    end

    def gitaly_migrate(method, &block)
      Gitlab::GitalyClient.migrate(method, &block)
    rescue GRPC::NotFound, GRPC::BadStatus => e
      # Old Popen code returns [Error, output] to the caller, so we
      # need to do the same here...
      raise Error, e
    end
  end
end
