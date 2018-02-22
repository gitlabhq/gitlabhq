namespace :gitlab do
  namespace :gitaly do
    desc "GitLab | Install or upgrade gitaly"
    task :install, [:dir, :repo] => :gitlab_environment do |t, args|
      require 'toml-rb'

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

      if Rails.env.test?
        command.push(
          'BUNDLE_FLAGS=--no-deployment',
          "BUNDLE_PATH=#{Bundler.bundle_path}")
      end

      Gitlab::SetupHelper.create_gitaly_configuration(args.dir)
      Dir.chdir(args.dir) do
        # In CI we run scripts/gitaly-test-build instead of this command
        unless ENV['CI'].present?
          Bundler.with_original_env { run_command!(command) }
        end
      end
    end

    desc "GitLab | Print storage configuration in TOML format"
    task storage_config: :environment do
      require 'toml-rb'

      puts "# Gitaly storage configuration generated from #{Gitlab.config.source} on #{Time.current.to_s(:long)}"
      puts "# This is in TOML format suitable for use in Gitaly's config.toml file."

      # Exclude gitaly-ruby configuration because that depends on the gitaly
      # installation directory.
      puts Gitlab::SetupHelper.gitaly_configuration_toml('', gitaly_ruby: false)
    end
  end
end
