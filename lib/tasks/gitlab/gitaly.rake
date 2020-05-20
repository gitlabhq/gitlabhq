namespace :gitlab do
  namespace :gitaly do
    desc 'GitLab | Gitaly | Install or upgrade gitaly'
    task :install, [:dir, :storage_path, :repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      unless args.dir.present? && args.storage_path.present?
        abort %(Please specify the directory where you want to install gitaly and the path for the default storage
Usage: rake "gitlab:gitaly:install[/installation/dir,/storage/path]")
      end

      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitaly.git')

      version = Gitlab::GitalyClient.expected_server_version

      checkout_or_clone_version(version: version, repo: args.repo, target_dir: args.dir, clone_opts: %w[--depth 1])

      command = []
      _, status = Gitlab::Popen.popen(%w[which gmake])
      command << (status.zero? ? 'gmake' : 'make')

      if Rails.env.test?
        command.push(
          'BUNDLE_FLAGS=--no-deployment',
          "BUNDLE_PATH=#{Bundler.bundle_path}")
      end

      storage_paths = { 'default' => args.storage_path }
      Gitlab::SetupHelper::Gitaly.create_configuration(args.dir, storage_paths)
      Dir.chdir(args.dir) do
        # In CI we run scripts/gitaly-test-build instead of this command
        unless ENV['CI'].present?
          Bundler.with_original_env { Gitlab::Popen.popen(command, nil, { "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil }) }
        end
      end
    end
  end
end
