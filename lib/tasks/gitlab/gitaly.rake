namespace :gitlab do
  namespace :gitaly do
    desc "GitLab | Install or upgrade gitaly"
    task :install, [:dir] => :environment do |t, args|
      warn_user_is_not_gitlab
      unless args.dir.present?
        abort %(Please specify the directory where you want to install gitaly:\n  rake "gitlab:gitaly:install[/home/git/gitaly]")
      end

      version = Gitlab::GitalyClient.expected_server_version
      repo = 'https://gitlab.com/gitlab-org/gitaly.git'

      checkout_or_clone_version(version: version, repo: repo, target_dir: args.dir)

      _, status = Gitlab::Popen.popen(%w[which gmake])
      command = status.zero? ? 'gmake' : 'make'

      Dir.chdir(args.dir) do
        run_command!([command])
      end
    end

    desc "GitLab | Print storage configuration in TOML format"
    task storage_config: :environment do
      require 'toml'

      puts "# Gitaly storage configuration generated from #{Gitlab.config.source} on #{Time.current.to_s(:long)}"
      puts "# This is in TOML format suitable for use in Gitaly's config.toml file."

      config = Gitlab.config.repositories.storages.map do |key, val|
        { name: key, path: val['path'] }
      end

      puts TOML.dump(storage: config)
    end
  end
end
