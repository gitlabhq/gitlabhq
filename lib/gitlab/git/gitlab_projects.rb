module Gitlab
  module Git
    class GitlabProjects
      include Gitlab::Git::Popen
      include Gitlab::Utils::StrongMemoize

      # Name of shard where repositories are stored.
      # Example: nfs-file06
      attr_reader :shard_name

      # Relative path is a directory name for repository with .git at the end.
      # Example: gitlab-org/gitlab-test.git
      attr_reader :repository_relative_path

      # This is the path at which the gitlab-shell hooks directory can be found.
      # It's essential for integration between git and GitLab proper. All new
      # repositories should have their hooks directory symlinked here.
      attr_reader :global_hooks_path

      attr_reader :logger

      def initialize(shard_name, repository_relative_path, global_hooks_path:, logger:)
        @shard_name = shard_name
        @repository_relative_path = repository_relative_path

        @logger = logger
        @global_hooks_path = global_hooks_path
        @output = StringIO.new
      end

      def output
        io = @output.dup
        io.rewind
        io.read
      end

      # Absolute path to the repository.
      # Example: /home/git/repositorities/gitlab-org/gitlab-test.git
      # Probably will be removed when we fully migrate to Gitaly, part of
      # https://gitlab.com/gitlab-org/gitaly/issues/1124.
      def repository_absolute_path
        strong_memoize(:repository_absolute_path) do
          File.join(shard_path, repository_relative_path)
        end
      end

      def shard_path
        strong_memoize(:shard_path) do
          Gitlab.config.repositories.storages.fetch(shard_name).legacy_disk_path
        end
      end

      # Import project via git clone --bare
      # URL must be publicly cloneable
      def import_project(source, timeout)
        Gitlab::GitalyClient.migrate(:import_repository) do |is_enabled|
          if is_enabled
            gitaly_import_repository(source)
          else
            git_import_repository(source, timeout)
          end
        end
      end

      def fork_repository(new_shard_name, new_repository_relative_path)
        Gitlab::GitalyClient.migrate(:fork_repository) do |is_enabled|
          if is_enabled
            gitaly_fork_repository(new_shard_name, new_repository_relative_path)
          else
            git_fork_repository(new_shard_name, new_repository_relative_path)
          end
        end
      end

      def fetch_remote(name, timeout, force:, tags:, ssh_key: nil, known_hosts: nil, prune: true)
        tags_option = tags ? '--tags' : '--no-tags'

        logger.info "Fetching remote #{name} for repository #{repository_absolute_path}."
        cmd = %W(#{Gitlab.config.git.bin_path} fetch #{name} --quiet)
        cmd << '--prune' if prune
        cmd << '--force' if force
        cmd << tags_option

        setup_ssh_auth(ssh_key, known_hosts) do |env|
          success = run_with_timeout(cmd, timeout, repository_absolute_path, env)

          unless success
            logger.error "Fetching remote #{name} for repository #{repository_absolute_path} failed."
          end

          success
        end
      end

      def push_branches(remote_name, timeout, force, branch_names)
        logger.info "Pushing branches from #{repository_absolute_path} to remote #{remote_name}: #{branch_names}"
        cmd = %W(#{Gitlab.config.git.bin_path} push)
        cmd << '--force' if force
        cmd += %W(-- #{remote_name}).concat(branch_names)

        success = run_with_timeout(cmd, timeout, repository_absolute_path)

        unless success
          logger.error("Pushing branches to remote #{remote_name} failed.")
        end

        success
      end

      def delete_remote_branches(remote_name, branch_names)
        branches = branch_names.map { |branch_name| ":#{branch_name}" }

        logger.info "Pushing deleted branches from #{repository_absolute_path} to remote #{remote_name}: #{branch_names}"
        cmd = %W(#{Gitlab.config.git.bin_path} push -- #{remote_name}).concat(branches)

        success = run(cmd, repository_absolute_path)

        unless success
          logger.error("Pushing deleted branches to remote #{remote_name} failed.")
        end

        success
      end

      protected

      def run(*args)
        output, exitstatus = popen(*args)
        @output << output

        exitstatus&.zero?
      end

      def run_with_timeout(*args)
        output, exitstatus = popen_with_timeout(*args)
        @output << output

        exitstatus&.zero?
      rescue Timeout::Error
        @output.puts('Timed out')

        false
      end

      def mask_password_in_url(url)
        result = URI(url)
        result.password = "*****" unless result.password.nil?
        result.user = "*****" unless result.user.nil? # it's needed for oauth access_token
        result
      rescue
        url
      end

      def remove_origin_in_repo
        cmd = %W(#{Gitlab.config.git.bin_path} remote rm origin)
        run(cmd, repository_absolute_path)
      end

      # Builds a small shell script that can be used to execute SSH with a set of
      # custom options.
      #
      # Options are expanded as `'-oKey="Value"'`, so SSH will correctly interpret
      # paths with spaces in them. We trust the user not to embed single or double
      # quotes in the key or value.
      def custom_ssh_script(options = {})
        args = options.map { |k, v| %Q{'-o#{k}="#{v}"'} }.join(' ')

        [
          "#!/bin/sh",
          "exec ssh #{args} \"$@\""
        ].join("\n")
      end

      # Known hosts data and private keys can be passed to gitlab-shell in the
      # environment. If present, this method puts them into temporary files, writes
      # a script that can substitute as `ssh`, setting the options to respect those
      # files, and yields: { "GIT_SSH" => "/tmp/myScript" }
      def setup_ssh_auth(key, known_hosts)
        options = {}

        if key
          key_file = Tempfile.new('gitlab-shell-key-file')
          key_file.chmod(0o400)
          key_file.write(key)
          key_file.close

          options['IdentityFile'] = key_file.path
          options['IdentitiesOnly'] = 'yes'
        end

        if known_hosts
          known_hosts_file = Tempfile.new('gitlab-shell-known-hosts')
          known_hosts_file.chmod(0o400)
          known_hosts_file.write(known_hosts)
          known_hosts_file.close

          options['StrictHostKeyChecking'] = 'yes'
          options['UserKnownHostsFile'] = known_hosts_file.path
        end

        return yield({}) if options.empty?

        script = Tempfile.new('gitlab-shell-ssh-wrapper')
        script.chmod(0o755)
        script.write(custom_ssh_script(options))
        script.close

        yield('GIT_SSH' => script.path)
      ensure
        key_file&.close!
        known_hosts_file&.close!
        script&.close!
      end

      private

      def git_import_repository(source, timeout)
        # Skip import if repo already exists
        return false if File.exist?(repository_absolute_path)

        masked_source = mask_password_in_url(source)

        logger.info "Importing project from <#{masked_source}> to <#{repository_absolute_path}>."
        cmd = %W(#{Gitlab.config.git.bin_path} clone --bare -- #{source} #{repository_absolute_path})

        success = run_with_timeout(cmd, timeout, nil)

        unless success
          logger.error("Importing project from <#{masked_source}> to <#{repository_absolute_path}> failed.")
          FileUtils.rm_rf(repository_absolute_path)
          return false
        end

        Gitlab::Git::Repository.create_hooks(repository_absolute_path, global_hooks_path)

        # The project was imported successfully.
        # Remove the origin URL since it may contain password.
        remove_origin_in_repo

        true
      end

      def gitaly_import_repository(source)
        raw_repository = Gitlab::Git::Repository.new(shard_name, repository_relative_path, nil)

        Gitlab::GitalyClient::RepositoryService.new(raw_repository).import_repository(source)
        true
      rescue GRPC::BadStatus => e
        @output << e.message
        false
      end

      def git_fork_repository(new_shard_name, new_repository_relative_path)
        from_path = repository_absolute_path
        new_shard_path = Gitlab.config.repositories.storages.fetch(new_shard_name).legacy_disk_path
        to_path = File.join(new_shard_path, new_repository_relative_path)

        # The repository cannot already exist
        if File.exist?(to_path)
          logger.error "fork-repository failed: destination repository <#{to_path}> already exists."
          return false
        end

        # Ensure the namepsace / hashed storage directory exists
        FileUtils.mkdir_p(File.dirname(to_path), mode: 0770)

        logger.info "Forking repository from <#{from_path}> to <#{to_path}>."
        cmd = %W(#{Gitlab.config.git.bin_path} clone --bare --no-local -- #{from_path} #{to_path})

        run(cmd, nil) && Gitlab::Git::Repository.create_hooks(to_path, global_hooks_path)
      end

      def gitaly_fork_repository(new_shard_name, new_repository_relative_path)
        target_repository = Gitlab::Git::Repository.new(new_shard_name, new_repository_relative_path, nil)
        raw_repository = Gitlab::Git::Repository.new(shard_name, repository_relative_path, nil)

        Gitlab::GitalyClient::RepositoryService.new(target_repository).fork_repository(raw_repository)
      rescue GRPC::BadStatus => e
        logger.error "fork-repository failed: #{e.message}"
        false
      end
    end
  end
end
