namespace :gitlab do
  namespace :shell do
    desc "GitLab | Install or upgrade gitlab-shell"
    task :install, [:repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      default_version = Gitlab::Shell.version_required
      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitlab-shell.git')

      gitlab_url = Gitlab.config.gitlab.url
      # gitlab-shell requires a / at the end of the url
      gitlab_url += '/' unless gitlab_url.end_with?('/')
      target_dir = Gitlab.config.gitlab_shell.path

      checkout_or_clone_version(version: default_version, repo: args.repo, target_dir: target_dir)

      # Make sure we're on the right tag
      Dir.chdir(target_dir) do
        config = {
          user: Gitlab.config.gitlab.user,
          gitlab_url: gitlab_url,
          http_settings: { self_signed_cert: false }.stringify_keys,
          auth_file: File.join(user_home, ".ssh", "authorized_keys"),
          redis: {
            bin: `which redis-cli`.chomp,
            namespace: "resque:gitlab"
          }.stringify_keys,
          log_level: "INFO",
          audit_usernames: false
        }.stringify_keys

        redis_url = URI.parse(ENV['REDIS_URL'] || "redis://localhost:6379")

        if redis_url.scheme == 'unix'
          config['redis']['socket'] = redis_url.path
        else
          config['redis']['host'] = redis_url.host
          config['redis']['port'] = redis_url.port
        end

        # Generate config.yml based on existing gitlab settings
        File.open("config.yml", "w+") {|f| f.puts config.to_yaml}

        [
          %w(bin/install) + repository_storage_paths_args,
          %w(bin/compile)
        ].each do |cmd|
          unless Kernel.system(*cmd)
            raise "command failed: #{cmd.join(' ')}"
          end
        end
      end

      # (Re)create hooks
      Rake::Task['gitlab:shell:create_hooks'].invoke

      Gitlab::Shell.ensure_secret_token!
    end

    desc "GitLab | Setup gitlab-shell"
    task setup: :gitlab_environment do
      setup
    end

    desc "GitLab | Build missing projects"
    task build_missing_projects: :gitlab_environment do
      Project.find_each(batch_size: 1000) do |project|
        path_to_repo = project.repository.path_to_repo
        if File.exist?(path_to_repo)
          print '-'
        else
          if Gitlab::Shell.new.create_repository(project.repository_storage,
                                              project.disk_path)
            print '.'
          else
            print 'F'
          end
        end
      end
    end

    desc 'Create or repair repository hooks symlink'
    task create_hooks: :gitlab_environment do
      warn_user_is_not_gitlab

      puts 'Creating/Repairing hooks symlinks for all repositories'
      system(*%W(#{Gitlab.config.gitlab_shell.path}/bin/create-hooks) + repository_storage_paths_args)
      puts 'done'.color(:green)
    end
  end

  def setup
    warn_user_is_not_gitlab

    unless ENV['force'] == 'yes'
      puts "This will rebuild an authorized_keys file."
      puts "You will lose any data stored in authorized_keys file."
      ask_to_continue
      puts ""
    end

    Gitlab::Shell.new.remove_all_keys

    Gitlab::Shell.new.batch_add_keys do |adder|
      Key.find_each(batch_size: 1000) do |key|
        adder.add_key(key.shell_id, key.key)
        print '.'
      end
    end
    puts ""

    unless $?.success?
      puts "Failed to add keys...".color(:red)
      exit 1
    end

  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".color(:red)
    exit 1
  end
end
