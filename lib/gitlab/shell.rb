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
    # storage - project's storage path
    # name - project path with namespace
    #
    # Ex.
    #   add_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def add_repository(storage, name)
      gitlab_shell_fast_execute([gitlab_shell_projects_path,
                                 'add-project', storage, "#{name}.git"])
    end

    # Import repository
    #
    # storage - project's storage path
    # name - project path with namespace
    #
    # Ex.
    #   import_repository("/path/to/storage", "gitlab/gitlab-ci", "https://github.com/randx/six.git")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def import_repository(storage, name, url)
      # Timeout should be less than 900 ideally, to prevent the memory killer
      # to silently kill the process without knowing we are timing out here.
      cmd = [gitlab_shell_projects_path, 'import-project',
             storage, "#{name}.git", url, "#{Gitlab.config.gitlab_shell.git_timeout}"]
      gitlab_shell_fast_execute_raise_error(cmd)
    end

    def list_remote_tags(storage, name, remote)
      output, status = Popen.popen([gitlab_shell_projects_path, 'list-remote-tags', storage, "#{name}.git", remote])
      tags_with_targets = []

      raise Error, output unless status.zero?

      # Each line has this format: "dc872e9fa6963f8f03da6c8f6f264d0845d6b092\trefs/tags/v1.10.0\n"
      # We want to convert it to: [{ 'v1.10.0' => 'dc872e9fa6963f8f03da6c8f6f264d0845d6b092' }, ...]
      output.lines.each do |line|
        target, path = line.strip!.split("\t")

        # When the remote repo does not have tags.
        if target.nil? || path.nil?
          Rails.logger.info "Empty or invalid list of tags for remote: #{remote}. Output: #{output}"
          break
        end

        name = path.split('/', 3).last
        # We're only interested in tag references
        # See: http://stackoverflow.com/questions/15472107/when-listing-git-ls-remote-why-theres-after-the-tag-name
        next if name =~ /\^\{\}\Z/

        tags_with_targets.concat([name, target])
      end

      Hash[*tags_with_targets]
    end

    # Fetch remote for repository
    #
    # name - project path with namespace
    # remote - remote name
    # forced - should we use --force flag?
    # no_tags - should we use --no-tags flag?
    #
    # Ex.
    #   fetch_remote("gitlab/gitlab-ci", "upstream")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def fetch_remote(storage, name, remote, forced: false, no_tags: false)
      args = [gitlab_shell_projects_path, 'fetch-remote', storage, "#{name}.git", remote, "#{Gitlab.config.gitlab_shell.git_timeout}"]
      args << '--force' if forced
      args << '--no-tags' if no_tags

      gitlab_shell_fast_execute_raise_error(args)
    end

    # Move repository
    # storage - project's storage path
    # path - project path with namespace
    # new_path - new project path with namespace
    #
    # Ex.
    #   mv_repository("/path/to/storage", "gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def mv_repository(storage, path, new_path)
      gitlab_shell_fast_execute([gitlab_shell_projects_path, 'mv-project',
                                 storage, "#{path}.git", "#{new_path}.git"])
    end

    # Move repository storage
    #
    # current_storage - project's current storage path
    # path - project path with namespace
    # new_storage - new storage path
    #
    # Ex.
    #   mv_storage("/path/to/storage", "randx/gitlab-ci", "/new/storage/path")
    #
    def mv_storage(current_storage, path, new_storage)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'mv-storage',
                                   current_storage, "#{path}.git", new_storage])
    end

    # Fork repository to new namespace
    # forked_from_storage - forked-from project's storage path
    # path - project path with namespace
    # forked_to_storage - forked-to project's storage path
    # fork_namespace - namespace for forked project
    #
    # Ex.
    #  fork_repository("/path/to/forked_from/storage", "gitlab/gitlab-ci", "/path/to/forked_to/storage", "randx")
    #
    # Gitaly note: JV: not easy to migrate because this involves two Gitaly servers, not one.
    def fork_repository(forked_from_storage, path, forked_to_storage, fork_namespace)
      gitlab_shell_fast_execute([gitlab_shell_projects_path, 'fork-project',
                                 forked_from_storage, "#{path}.git", forked_to_storage,
                                 fork_namespace])
    end

    # Remove repository from file system
    #
    # storage - project's storage path
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/387
    def remove_repository(storage, name)
      gitlab_shell_fast_execute([gitlab_shell_projects_path,
                                 'rm-project', storage, "#{name}.git"])
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
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def add_namespace(storage, name)
      path = full_path(storage, name)
      FileUtils.mkdir_p(path, mode: 0770) unless exists?(storage, name)
    rescue Errno::EEXIST => e
      Rails.logger.warn("Directory exists as a file: #{e} at: #{path}")
    end

    # Remove directory from repositories storage
    # Every repository inside this directory will be removed too
    #
    # Ex.
    #   rm_namespace("/path/to/storage", "gitlab")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def rm_namespace(storage, name)
      FileUtils.rm_r(full_path(storage, name), force: true)
    end

    # Move namespace directory inside repositories storage
    #
    # Ex.
    #   mv_namespace("/path/to/storage", "gitlab", "gitlabhq")
    #
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/385
    def mv_namespace(storage, old_name, new_name)
      return false if exists?(storage, new_name) || !exists?(storage, old_name)

      FileUtils.mv(full_path(storage, old_name), full_path(storage, new_name))
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
      File.exist?(full_path(storage, dir_name))
    end

    # Create (if necessary) and link the secret token file
    def generate_and_link_secret_token
      secret_file = Gitlab.config.gitlab_shell.secret_file
      unless File.size?(secret_file)
        # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
        token = SecureRandom.hex(16)
        File.write(secret_file, token)
      end

      link_path = File.join(gitlab_shell_path, '.gitlab_shell_secret')
      if File.exist?(gitlab_shell_path) && !File.exist?(link_path)
        FileUtils.symlink(secret_file, link_path)
      end
    end

    # Push branch to remote repository
    #
    # project_name - project's name with namespace
    # remote_name - remote name
    # branch_name - remote branch name
    #
    # Ex.
    #   push_remote_branches('upstream', 'feature')
    #
    def push_remote_branches(storage, project_name, remote_name, branch_names)
      args = [gitlab_shell_projects_path, 'push-branches', storage, "#{project_name}.git", remote_name, '600', *branch_names]
      output, status = Popen.popen(args)
      raise Error, output unless status.zero?
      true
    end

    # Delete branch from remote repository
    #
    # project_name - project's name with namespace
    # remote_name - remote name
    # branch_name - remote branch name
    #
    # Ex.
    #   delete_remote_branches('upstream', 'feature')
    #
    def delete_remote_branches(storage, project_name, remote_name, branch_names)
      args = [gitlab_shell_projects_path, 'delete-remote-branches', storage, "#{project_name}.git", remote_name, *branch_names]
      output, status = Popen.popen(args)
      raise Error, output unless status.zero?
      true
    end

    protected

    def gitlab_shell_path
      Gitlab.config.gitlab_shell.path
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
      return true if current_application_settings.authorized_keys_enabled.nil?

      current_application_settings.authorized_keys_enabled
    end

    private

    def gitlab_shell_fast_execute(cmd)
      output, status = gitlab_shell_fast_execute_helper(cmd)

      return true if status.zero?

      Rails.logger.error("gitlab-shell failed with error #{status}: #{output}")
      false
    end

    def gitlab_shell_fast_execute_raise_error(cmd)
      output, status = gitlab_shell_fast_execute_helper(cmd)

      raise Error, output unless status.zero?
      true
    end

    def gitlab_shell_fast_execute_helper(cmd)
      vars = ENV.to_h.slice(*GITLAB_SHELL_ENV_VARS)

      # Don't pass along the entire parent environment to prevent gitlab-shell
      # from wasting I/O by searching through GEM_PATH
      Bundler.with_original_env { Popen.popen(cmd, nil, vars) }
    end
  end
end
