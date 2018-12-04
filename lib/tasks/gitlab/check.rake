namespace :gitlab do
  desc 'GitLab | Check the configuration of GitLab and its environment'
  task check: %w{gitlab:gitlab_shell:check
                 gitlab:gitaly:check
                 gitlab:sidekiq:check
                 gitlab:incoming_email:check
                 gitlab:ldap:check
                 gitlab:app:check}

  namespace :app do
    desc 'GitLab | Check the configuration of the GitLab Rails app'
    task check: :gitlab_environment do
      warn_user_is_not_gitlab

      checks = [
        SystemCheck::App::GitConfigCheck,
        SystemCheck::App::DatabaseConfigExistsCheck,
        SystemCheck::App::MigrationsAreUpCheck,
        SystemCheck::App::OrphanedGroupMembersCheck,
        SystemCheck::App::GitlabConfigExistsCheck,
        SystemCheck::App::GitlabConfigUpToDateCheck,
        SystemCheck::App::LogWritableCheck,
        SystemCheck::App::TmpWritableCheck,
        SystemCheck::App::UploadsDirectoryExistsCheck,
        SystemCheck::App::UploadsPathPermissionCheck,
        SystemCheck::App::UploadsPathTmpPermissionCheck,
        SystemCheck::App::InitScriptExistsCheck,
        SystemCheck::App::InitScriptUpToDateCheck,
        SystemCheck::App::ProjectsHaveNamespaceCheck,
        SystemCheck::App::RedisVersionCheck,
        SystemCheck::App::RubyVersionCheck,
        SystemCheck::App::GitVersionCheck,
        SystemCheck::App::GitUserDefaultSSHConfigCheck,
        SystemCheck::App::ActiveUsersCheck
      ]

      SystemCheck.run('GitLab', checks)
    end
  end

  namespace :gitlab_shell do
    desc "GitLab | Check the configuration of GitLab Shell"
    task check: :gitlab_environment do
      warn_user_is_not_gitlab
      start_checking "GitLab Shell"

      check_gitlab_shell
      check_gitlab_shell_self_test

      finished_checking "GitLab Shell"
    end

    # Checks
    ########################

    def check_gitlab_shell_self_test
      gitlab_shell_repo_base = gitlab_shell_path
      check_cmd = File.expand_path('bin/check', gitlab_shell_repo_base)
      puts "Running #{check_cmd}"

      if system(check_cmd, chdir: gitlab_shell_repo_base)
        puts 'gitlab-shell self-check successful'.color(:green)
      else
        puts 'gitlab-shell self-check failed'.color(:red)
        try_fixing_it(
          'Make sure GitLab is running;',
          'Check the gitlab-shell configuration file:',
          sudo_gitlab("editor #{File.expand_path('config.yml', gitlab_shell_repo_base)}")
        )
        fix_and_rerun
      end
    end

    # Helper methods
    ########################

    def gitlab_shell_path
      Gitlab.config.gitlab_shell.path
    end

    def gitlab_shell_version
      Gitlab::Shell.new.version
    end

    def gitlab_shell_major_version
      Gitlab::Shell.version_required.split('.')[0].to_i
    end

    def gitlab_shell_minor_version
      Gitlab::Shell.version_required.split('.')[1].to_i
    end

    def gitlab_shell_patch_version
      Gitlab::Shell.version_required.split('.')[2].to_i
    end
  end

  namespace :gitaly do
    desc 'GitLab | Check the health of Gitaly'
    task check: :gitlab_environment do
      warn_user_is_not_gitlab
      start_checking 'Gitaly'

      Gitlab::HealthChecks::GitalyCheck.readiness.each do |result|
        print "#{result.labels[:shard]} ... "

        if result.success
          puts 'OK'.color(:green)
        else
          puts "FAIL: #{result.message}".color(:red)
        end
      end

      finished_checking 'Gitaly'
    end
  end

  namespace :sidekiq do
    desc "GitLab | Check the configuration of Sidekiq"
    task check: :gitlab_environment do
      warn_user_is_not_gitlab
      start_checking "Sidekiq"

      check_sidekiq_running
      only_one_sidekiq_running

      finished_checking "Sidekiq"
    end

    # Checks
    ########################

    def check_sidekiq_running
      print "Running? ... "

      if sidekiq_process_count > 0
        puts "yes".color(:green)
      else
        puts "no".color(:red)
        try_fixing_it(
          sudo_gitlab("RAILS_ENV=production bin/background_jobs start")
        )
        for_more_information(
          see_installation_guide_section("Install Init Script"),
          "see log/sidekiq.log for possible errors"
        )
        fix_and_rerun
      end
    end

    def only_one_sidekiq_running
      process_count = sidekiq_process_count
      return if process_count.zero?

      print 'Number of Sidekiq processes ... '

      if process_count == 1
        puts '1'.color(:green)
      else
        puts "#{process_count}".color(:red)
        try_fixing_it(
          'sudo service gitlab stop',
          "sudo pkill -u #{gitlab_user} -f sidekiq",
          "sleep 10 && sudo pkill -9 -u #{gitlab_user} -f sidekiq",
          'sudo service gitlab start'
        )
        fix_and_rerun
      end
    end

    def sidekiq_process_count
      ps_ux, _ = Gitlab::Popen.popen(%w(ps uxww))
      ps_ux.scan(/sidekiq \d+\.\d+\.\d+/).count
    end
  end

  namespace :incoming_email do
    desc "GitLab | Check the configuration of Reply by email"
    task check: :gitlab_environment do
      warn_user_is_not_gitlab

      if Gitlab.config.incoming_email.enabled
        checks = [
          SystemCheck::IncomingEmail::ImapAuthenticationCheck
        ]

        if Rails.env.production?
          checks << SystemCheck::IncomingEmail::InitdConfiguredCheck
          checks << SystemCheck::IncomingEmail::MailRoomRunningCheck
        else
          checks << SystemCheck::IncomingEmail::ForemanConfiguredCheck
        end

        SystemCheck.run('Reply by email', checks)
      else
        puts 'Reply by email is disabled in config/gitlab.yml'
      end
    end
  end

  namespace :ldap do
    task :check, [:limit] => :gitlab_environment do |_, args|
      # Only show up to 100 results because LDAP directories can be very big.
      # This setting only affects the `rake gitlab:check` script.
      args.with_defaults(limit: 100)
      warn_user_is_not_gitlab
      start_checking "LDAP"

      if Gitlab::Auth::LDAP::Config.enabled?
        check_ldap(args.limit)
      else
        puts 'LDAP is disabled in config/gitlab.yml'
      end

      finished_checking "LDAP"
    end

    def check_ldap(limit)
      servers = Gitlab::Auth::LDAP::Config.providers

      servers.each do |server|
        puts "Server: #{server}"

        begin
          Gitlab::Auth::LDAP::Adapter.open(server) do |adapter|
            check_ldap_auth(adapter)

            puts "LDAP users with access to your GitLab server (only showing the first #{limit} results)"

            users = adapter.users(adapter.config.uid, '*', limit)
            users.each do |user|
              puts "\tDN: #{user.dn}\t #{adapter.config.uid}: #{user.uid}"
            end
          end
        rescue Net::LDAP::ConnectionRefusedError, Errno::ECONNREFUSED => e
          puts "Could not connect to the LDAP server: #{e.message}".color(:red)
        end
      end
    end

    def check_ldap_auth(adapter)
      auth = adapter.config.has_auth?

      message = if auth && adapter.ldap.bind
                  'Success'.color(:green)
                elsif auth
                  'Failed. Check `bind_dn` and `password` configuration values'.color(:red)
                else
                  'Anonymous. No `bind_dn` or `password` configured'.color(:yellow)
                end

      puts "LDAP authentication... #{message}"
    end
  end

  namespace :orphans do
    desc 'Gitlab | Check for orphaned namespaces and repositories'
    task check: :gitlab_environment do
      warn_user_is_not_gitlab
      checks = [
        SystemCheck::Orphans::NamespaceCheck,
        SystemCheck::Orphans::RepositoryCheck
      ]

      SystemCheck.run('Orphans', checks)
    end

    desc 'GitLab | Check for orphaned namespaces in the repositories path'
    task check_namespaces: :gitlab_environment do
      warn_user_is_not_gitlab
      checks = [SystemCheck::Orphans::NamespaceCheck]

      SystemCheck.run('Orphans', checks)
    end

    desc 'GitLab | Check for orphaned repositories in the repositories path'
    task check_repositories: :gitlab_environment do
      warn_user_is_not_gitlab
      checks = [SystemCheck::Orphans::RepositoryCheck]

      SystemCheck.run('Orphans', checks)
    end
  end

  # Helper methods
  ##########################

  def check_gitlab_shell
    required_version = Gitlab::VersionInfo.new(gitlab_shell_major_version, gitlab_shell_minor_version, gitlab_shell_patch_version)
    current_version = Gitlab::VersionInfo.parse(gitlab_shell_version)

    print "GitLab Shell version >= #{required_version} ? ... "
    if current_version.valid? && required_version <= current_version
      puts "OK (#{current_version})".color(:green)
    else
      puts "FAIL. Please update gitlab-shell to #{required_version} from #{current_version}".color(:red)
    end
  end
end
