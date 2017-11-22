namespace :gitlab do
  namespace :gitaly do
    desc "GitLab | Install or upgrade gitaly"
    task :install, [:dir, :repo] => :environment do |t, args|
      require 'toml'

      warn_user_is_not_gitlab
      unless args.dir.present?
        abort %(Please specify the directory where you want to install gitaly:\n  rake "gitlab:gitaly:install[/home/git/gitaly]")
      end
      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitaly.git')

      version = Gitlab::GitalyClient.expected_server_version

      checkout_or_clone_version(version: version, repo: args.repo, target_dir: args.dir)

      command = %w[/usr/bin/env -u RUBYOPT -u BUNDLE_GEMFILE]

      _, status = Gitlab::Popen.popen(%w[which gmake])
      command << (status.zero? ? 'gmake' : 'make')

      command << 'BUNDLE_FLAGS=--no-deployment' if Rails.env.test?

      Dir.chdir(args.dir) do
        create_gitaly_configuration
        # In CI we run scripts/gitaly-test-build instead of this command
        unless ENV['CI'].present?
          Bundler.with_original_env { run_command!(command) }
        end
      end
    end

    desc "GitLab | Print storage configuration in TOML format"
    task storage_config: :environment do
      require 'toml'

      puts "# Gitaly storage configuration generated from #{Gitlab.config.source} on #{Time.current.to_s(:long)}"
      puts "# This is in TOML format suitable for use in Gitaly's config.toml file."

      # Exclude gitaly-ruby configuration because that depends on the gitaly
      # installation directory.
      puts gitaly_configuration_toml(gitaly_ruby: false)
    end

    private

    # We cannot create config.toml files for all possible Gitaly configuations.
    # For instance, if Gitaly is running on another machine then it makes no
    # sense to write a config.toml file on the current machine. This method will
    # only generate a configuration for the most common and simplest case: when
    # we have exactly one Gitaly process and we are sure it is running locally
    # because it uses a Unix socket.
    # For development and testing purposes, an extra storage is added to gitaly,
    # which is not known to Rails, but must be explicitly stubbed.
    def gitaly_configuration_toml(gitaly_ruby: true)
      storages = []
      address = nil

      Gitlab.config.repositories.storages.each do |key, val|
        if address
          if address != val['gitaly_address']
            raise ArgumentError, "Your gitlab.yml contains more than one gitaly_address."
          end
        elsif URI(val['gitaly_address']).scheme != 'unix'
          raise ArgumentError, "Automatic config.toml generation only supports 'unix:' addresses."
        else
          address = val['gitaly_address']
        end

        storages << { name: key, path: val['path'] }
      end

      if Rails.env.test?
        storages << { name: 'test_second_storage', path: Rails.root.join('tmp', 'tests', 'second_storage').to_s }
      end

      config = { socket_path: address.sub(%r{\Aunix:}, ''), storage: storages }
      config[:auth] = { token: 'secret' } if Rails.env.test?
      config[:'gitaly-ruby'] = { dir: File.join(Dir.pwd, 'ruby') } if gitaly_ruby
      config[:'gitlab-shell'] = { dir: Gitlab.config.gitlab_shell.path }
      config[:bin_dir] = Gitlab.config.gitaly.client_path

      TOML.dump(config)
    end

    def create_gitaly_configuration
      File.open("config.toml", File::WRONLY | File::CREAT | File::EXCL) do |f|
        f.puts gitaly_configuration_toml
      end
    rescue Errno::EEXIST
      puts "Skipping config.toml generation:"
      puts "A configuration file already exists."
    rescue ArgumentError => e
      puts "Skipping config.toml generation:"
      puts e.message
    end
  end
end
