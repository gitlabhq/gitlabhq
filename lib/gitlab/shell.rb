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
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def add_repository(storage, name)
      relative_path = name.dup
      relative_path << '.git' unless relative_path.end_with?('.git')

      gitaly_migrate(:create_repository) do |is_enabled|
        if is_enabled
          repository = Gitlab::Git::Repository.new(storage, relative_path, '')
          repository.gitaly_repository_client.create_repository
          true
        else
          repo_path = File.join(Gitlab.config.repositories.storages[storage]['path'], relative_path)
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
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def import_repository(storage, name, url)
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
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def fetch_remote(repository, remote, ssh_auth: nil, forced: false, no_tags: false)
      gitaly_migrate(:fetch_remote) do |is_enabled|
        if is_enabled
          repository.gitaly_repository_client.fetch_remote(remote, ssh_auth: ssh_auth, forced: forced, no_tags: no_tags)
        else
          storage_path = Gitlab.config.repositories.storages[repository.storage]["path"]
          local_fetch_remote(storage_path, repository.relative_path, remote, ssh_auth: ssh_auth, forced: forced, no_tags: no_tags)
        end
      end
    end

    # Move repository
    # storage - project's storage path
    # path - project disk path
    # new_path - new project disk path
    #
    # Ex.
    #   mv_repository("/path/to/storage", "gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def mv_repository(storage, path, new_path)
      gitlab_projects(storage, "#{path}.git").mv_project("#{new_path}.git")
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
    # Gitaly note: JV: not easy to migrate because this involves two Gitaly servers, not one.
    def fork_repository(forked_from_storage, forked_from_disk_path, forked_to_storage, forked_to_disk_path)
      gitlab_projects(forked_from_storage, "#{forked_from_disk_path}.git")
        .fork_repository(forked_to_storage, "#{forked_to_disk_path}.git")
    end

    # Remove repository from file system
    #
    # storage - project's storage path
    # name - project disk path
    #
    # Ex.
    #   remove_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def remove_repository(storage, name)
      gitlab_projects(storage, "#{name}.git").rm_project
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("key-42", "sha-rsa ...")
    #
    def add_key(key_id, key_content)
      gitlab_shell_fast_execute([gitlab_shell_keys_path,
                                 'add-key', key_id, self.class.strip_key(key_content)])
    end

    # Batch-add keys to authorized_keys
    #
    # Ex.
    #   batch_add_keys { |adder| adder.add_key("key-42", "sha-rsa ...") }
    def batch_add_keys(&block)
      IO.popen(%W(#{gitlab_shell_path}/bin/gitlab-keys batch-add-keys), 'w') do |io|
        yield(KeyAdder.new(io))
      end
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("key-342", "sha-rsa ...")
    #
    def remove_key(key_id, key_content)
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
      gitlab_shell_fast_execute([gitlab_shell_keys_path, 'clear'])
    end

    # Add empty directory for storing repositories
    #
    # Ex.
    #   add_namespace("/path/to/storage", "gitlab")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def add_namespace(storage, name)
      Gitlab::GitalyClient.migrate(:add_namespace) do |enabled|
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
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def rm_namespace(storage, name)
      Gitlab::GitalyClient.migrate(:remove_namespace) do |enabled|
        if enabled
          gitaly_namespace_client(storage).remove(name)
        else
          FileUtils.rm_r(full_path(storage, name), force: true)
        end
      end
    rescue GRPC::InvalidArgument => e
      raise ArgumentError, e.message
    end

    # Move namespace directory inside repositories storage
    #
    # Ex.
    #   mv_namespace("/path/to/storage", "gitlab", "gitlabhq")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def mv_namespace(storage, old_name, new_name)
      Gitlab::GitalyClient.migrate(:rename_namespace) do |enabled|
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
      Gitlab::GitalyClient.migrate(:namespace_exists) do |enabled|
        if enabled
          gitaly_namespace_client(storage).exists?(dir_name)
        else
          File.exist?(full_path(storage, dir_name))
        end
      end
    end

    # Push branch to remote repository
    #
    # storage - project's storage path
    # project_name - project's disk path
    # remote_name - remote name
    # branch_names - remote branch names to push
    # forced - should we use --force flag
    #
    # Ex.
    #   push_remote_branches('/path/to/storage', 'gitlab-org/gitlab-test' 'upstream', ['feature'])
    #
    def push_remote_branches(storage, project_name, remote_name, branch_names, forced: true)
      cmd = gitlab_projects(storage, "#{project_name}.git")

      success = cmd.push_branches(remote_name, git_timeout, forced, branch_names)

      raise Error, cmd.output unless success

      success
    end

    # Delete branch from remote repository
    #
    # storage - project's storage path
    # project_name - project's disk path
    # remote_name - remote name
    # branch_names - remote branch names
    #
    # Ex.
    #   delete_remote_branches('/path/to/storage', 'gitlab-org/gitlab-test', 'upstream', ['feature'])
    #
    def delete_remote_branches(storage, project_name, remote_name, branch_names)
      cmd = gitlab_projects(storage, "#{project_name}.git")

      success = cmd.delete_remote_branches(remote_name, branch_names)

      raise Error, cmd.output unless success

      success
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

    private

    def gitlab_projects(shard_path, disk_path)
      Gitlab::Git::GitlabProjects.new(
        shard_path,
        disk_path,
        global_hooks_path: Gitlab.config.gitlab_shell.hooks_path,
        logger: Rails.logger
      )
    end

    def local_fetch_remote(storage_path, repository_relative_path, remote, ssh_auth: nil, forced: false, no_tags: false)
      vars = { force: forced, tags: !no_tags }

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
        value['path'] == storage_path
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
