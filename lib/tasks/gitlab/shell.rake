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

    ensure_write_to_authorized_keys_is_enabled

    unless ENV['force'] == 'yes'
      puts "This task will now rebuild the authorized_keys file."
      puts "You will lose any data stored in the authorized_keys file."
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

  def ensure_write_to_authorized_keys_is_enabled
    return if Gitlab::CurrentSettings.current_application_settings.authorized_keys_enabled

    puts authorized_keys_is_disabled_warning

    answer = prompt('Do you want to permanently enable the "Write to authorized_keys file" setting now (yes/no)? '.color(:blue), %w{yes no})
    if answer == 'yes'
      puts 'Enabling the "Write to authorized_keys file" setting...'
      uncached_settings = ApplicationSetting.last
      uncached_settings.authorized_keys_enabled = true
      uncached_settings.save!
      puts 'Successfully enabled "Write to authorized_keys file"!'
      puts ''
    else
      puts 'Leaving the "Write to authorized_keys file" setting disabled.'
      puts 'Failed to rebuild authorized_keys file...'.color(:red)
      exit 1
    end
  end

  def authorized_keys_is_disabled_warning
    <<-MSG.strip_heredoc
      WARNING

      The "Write to authorized_keys file" setting is disabled, which prevents
      the file from being rebuilt!

      It should be enabled for most GitLab installations. Large installations
      may wish to disable it as part of speeding up SSH operations.

      See https://docs.gitlab.com/ee/administration/operations/fast_ssh_key_lookup.html

      If you did not intentionally disable this option in Admin Area > Settings,
      then you may have been affected by the 9.3.0 bug in which the new setting
      was disabled by default.

      https://gitlab.com/gitlab-org/gitlab-ee/issues/2738

      It was reverted in 9.3.1 and fixed in 9.3.3, however, if Settings were
      saved while the setting was unchecked, then it is still disabled.
    MSG
  end
end
