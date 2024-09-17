# frozen_string_literal: true

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
          auth_file: File.join(user_home, ".ssh", "authorized_keys"),
          log_level: "INFO",
          audit_usernames: false
        }.stringify_keys

        # Generate config.yml based on existing gitlab settings
        File.open("config.yml", "w+") { |f| f.puts config.to_yaml }

        [
          %w[make make_necessary_dirs build]
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
      setup_gitlab_shell
    end
  end

  def setup_gitlab_shell
    unless Gitlab::CurrentSettings.authorized_keys_enabled?
      puts 'The "Write to authorized_keys" setting is disabled. Skipping rebuilding the authorized_keys file...'
      return
    end

    warn_user_is_not_gitlab

    unless ENV['force'] == 'yes'
      puts "This task will now rebuild the authorized_keys file."
      puts "You will lose any data stored in the authorized_keys file."
      ask_to_continue
      puts ""
    end

    authorized_keys = Gitlab::AuthorizedKeys.new

    authorized_keys.clear

    Key.auth.find_in_batches(batch_size: 1000) do |keys|
      unless authorized_keys.batch_add_keys(keys)
        puts Rainbow("Failed to add keys...").red
        exit 1
      end
    end
  rescue Gitlab::TaskAbortedByUserError
    puts Rainbow("Quitting...").red
    exit 1
  end
end
