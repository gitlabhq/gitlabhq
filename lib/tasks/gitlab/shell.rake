namespace :gitlab do
  namespace :shell do
    desc "GitLab | Shell | Install or upgrade gitlab-shell"
    task :install, [:repo] => :gitlab_environment do |t, args|
      warn_user_is_not_gitlab

      default_version = Gitlab::Shell.version_required
      args.with_defaults(repo: 'https://gitlab.com/gitlab-org/gitlab-shell.git')

      gitlab_url = Gitlab.config.gitlab.url
      # gitlab-shell requires a / at the end of the url
      gitlab_url += '/' unless gitlab_url.end_with?('/')
      target_dir = Gitlab.config.gitlab_shell.path

      checkout_or_clone_version(version: default_version, repo: args.repo, target_dir: target_dir, clone_opts: %w[--depth 1])

      # Make sure we're on the right tag
      Dir.chdir(target_dir) do
        config = {
          user: Gitlab.config.gitlab.user,
          gitlab_url: gitlab_url,
          http_settings: { self_signed_cert: false }.stringify_keys,
          auth_file: File.join(user_home, ".ssh", "authorized_keys"),
          log_level: "INFO",
          audit_usernames: false
        }.stringify_keys

        # Generate config.yml based on existing gitlab settings
        File.open("config.yml", "w+") {|f| f.puts config.to_yaml }

        [
          %w(bin/install) + repository_storage_paths_args,
          %w(make build)
        ].each do |cmd|
          unless Kernel.system(*cmd)
            raise "command failed: #{cmd.join(' ')}"
          end
        end
      end

      Gitlab::Shell.ensure_secret_token!
    end

    desc "GitLab | Shell | Setup gitlab-shell"
    task setup: :gitlab_environment do
      setup
    end

    desc "GitLab | Shell | Build missing projects"
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

    authorized_keys = Gitlab::AuthorizedKeys.new

    authorized_keys.clear

    Key.find_in_batches(batch_size: 1000) do |keys|
      unless authorized_keys.batch_add_keys(keys)
        puts "Failed to add keys...".color(:red)
        exit 1
      end
    end
  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".color(:red)
    exit 1
  end

  def ensure_write_to_authorized_keys_is_enabled
    return if Gitlab::CurrentSettings.authorized_keys_enabled?

    puts authorized_keys_is_disabled_warning

    unless ENV['force'] == 'yes'
      puts 'Do you want to permanently enable the "Write to authorized_keys file" setting now?'
      ask_to_continue
    end

    puts 'Enabling the "Write to authorized_keys file" setting...'
    Gitlab::CurrentSettings.update!(authorized_keys_enabled: true)

    puts 'Successfully enabled "Write to authorized_keys file"!'
    puts ''
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

      https://gitlab.com/gitlab-org/gitlab/issues/2738

      It was reverted in 9.3.1 and fixed in 9.3.3, however, if Settings were
      saved while the setting was unchecked, then it is still disabled.
    MSG
  end
end
