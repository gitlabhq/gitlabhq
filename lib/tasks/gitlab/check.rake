namespace :gitlab do
  desc "GitLab | Check the configuration of GitLab and its environment"
  task check: %w{gitlab:gitlab_shell:check
                 gitlab:sidekiq:check
                 gitlab:incoming_email:check
                 gitlab:ldap:check
                 gitlab:app:check}



  namespace :app do
    desc "GitLab | Check the configuration of the GitLab Rails app"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "GitLab"

      check_git_config
      check_database_config_exists
      check_database_is_not_sqlite
      check_migrations_are_up
      check_orphaned_group_members
      check_gitlab_config_exists
      check_gitlab_config_not_outdated
      check_log_writable
      check_tmp_writable
      check_uploads
      check_init_script_exists
      check_init_script_up_to_date
      check_projects_have_namespace
      check_redis_version
      check_ruby_version
      check_git_version
      check_active_users

      finished_checking "GitLab"
    end


    # Checks
    ########################

    def check_git_config
      print "Git configured with autocrlf=input? ... "

      options = {
        "core.autocrlf" => "input"
      }

      correct_options = options.map do |name, value|
        run(%W(#{Gitlab.config.git.bin_path} config --global --get #{name})).try(:squish) == value
      end

      if correct_options.all?
        puts "yes".green
      else
        print "Trying to fix Git error automatically. ..."

        if auto_fix_git_config(options)
          puts "Success".green
        else
          puts "Failed".red
          try_fixing_it(
            sudo_gitlab("\"#{Gitlab.config.git.bin_path}\" config --global core.autocrlf \"#{options["core.autocrlf"]}\"")
          )
          for_more_information(
            see_installation_guide_section "GitLab"
          )
       end
      end
    end

    def check_database_config_exists
      print "Database config exists? ... "

      database_config_file = Rails.root.join("config", "database.yml")

      if File.exists?(database_config_file)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Copy config/database.yml.<your db> to config/database.yml",
          "Check that the information in config/database.yml is correct"
        )
        for_more_information(
          see_database_guide,
          "http://guides.rubyonrails.org/getting_started.html#configuring-a-database"
        )
        fix_and_rerun
      end
    end

    def check_database_is_not_sqlite
      print "Database is SQLite ... "

      database_config_file = Rails.root.join("config", "database.yml")

      unless File.read(database_config_file) =~ /adapter:\s+sqlite/
        puts "no".green
      else
        puts "yes".red
        puts "Please fix this by removing the SQLite entry from the database.yml".blue
        for_more_information(
          "https://github.com/gitlabhq/gitlabhq/wiki/Migrate-from-SQLite-to-MySQL",
          see_database_guide
        )
        fix_and_rerun
      end
    end

    def check_gitlab_config_exists
      print "GitLab config exists? ... "

      gitlab_config_file = Rails.root.join("config", "gitlab.yml")

      if File.exists?(gitlab_config_file)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Copy config/gitlab.yml.example to config/gitlab.yml",
          "Update config/gitlab.yml to match your setup"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        fix_and_rerun
      end
    end

    def check_gitlab_config_not_outdated
      print "GitLab config outdated? ... "

      gitlab_config_file = Rails.root.join("config", "gitlab.yml")
      unless File.exists?(gitlab_config_file)
        puts "can't check because of previous errors".magenta
      end

      # omniauth or ldap could have been deleted from the file
      unless Gitlab.config['git_host']
        puts "no".green
      else
        puts "yes".red
        try_fixing_it(
          "Backup your config/gitlab.yml",
          "Copy config/gitlab.yml.example to config/gitlab.yml",
          "Update config/gitlab.yml to match your setup"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        fix_and_rerun
      end
    end

    def check_init_script_exists
      print "Init script exists? ... "

      if omnibus_gitlab?
        puts 'skipped (omnibus-gitlab has no init script)'.magenta
        return
      end

      script_path = "/etc/init.d/gitlab"

      if File.exists?(script_path)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Install the init script"
        )
        for_more_information(
          see_installation_guide_section "Install Init Script"
        )
        fix_and_rerun
      end
    end

    def check_init_script_up_to_date
      print "Init script up-to-date? ... "

      if omnibus_gitlab?
        puts 'skipped (omnibus-gitlab has no init script)'.magenta
        return
      end

      recipe_path = Rails.root.join("lib/support/init.d/", "gitlab")
      script_path = "/etc/init.d/gitlab"

      unless File.exists?(script_path)
        puts "can't check because of previous errors".magenta
        return
      end

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
      recipe_content = File.read(recipe_path)
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-0-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/4-0-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-0-stable/init.d/gitlab 2>/dev/null`
>>>>>>> origin/4-0-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/4-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/4-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> origin/4-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-2-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/4-2-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/4-2-stable/init.d/gitlab 2>/dev/null`
>>>>>>> origin/4-2-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/5-0-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/5-0-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/5-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/5-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/5-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> origin/5-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlabhq/5-2-stable/lib/support/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/5-2-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/5-0-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/5-0-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/5-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/5-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/5-1-stable/init.d/gitlab 2>/dev/null`
>>>>>>> origin/5-1-stable
=======
      recipe_content = `curl https://raw.github.com/gitlabhq/gitlabhq/5-2-stable/lib/support/init.d/gitlab 2>/dev/null`
>>>>>>> gitlabhq/5-2-stable
      script_content = File.read(script_path)

      if recipe_content == script_content
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Redownload the init script"
        )
        for_more_information(
          see_installation_guide_section "Install Init Script"
        )
        fix_and_rerun
      end
    end

    def check_migrations_are_up
      print "All migrations up? ... "

      migration_status, _ = Gitlab::Popen.popen(%W(bundle exec rake db:migrate:status))

      unless migration_status =~ /down\s+\d{14}/
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
<<<<<<< HEAD
<<<<<<< HEAD
          sudo_gitlab("bundle exec rake db:migrate RAILS_ENV=production")
=======
          "sudo -u gitlab -H bundle exec rake db:migrate RAILS_ENV=production"
>>>>>>> gitlabhq/4-0-stable
=======
          "sudo -u gitlab -H bundle exec rake db:migrate RAILS_ENV=production"
>>>>>>> origin/4-0-stable
        )
        fix_and_rerun
      end
    end

<<<<<<< HEAD
    def check_orphaned_group_members
      print "Database contains orphaned GroupMembers? ... "
      if GroupMember.where("user_id not in (select id from users)").count > 0
        puts "yes".red
        try_fixing_it(
          "You can delete the orphaned records using something along the lines of:",
          sudo_gitlab("bundle exec rails runner -e production 'GroupMember.where(\"user_id NOT IN (SELECT id FROM users)\").delete_all'")
        )
      else
        puts "no".green
=======
    def check_satellites_exist
      print "Projects have satellites? ... "

      unless Project.count > 0
        puts "can't check, you have no projects".magenta
        return
      end
      puts ""

      Project.find_each(batch_size: 100) do |project|
        print "#{project.name_with_namespace.yellow} ... "

        if project.satellite.exists?
          puts "yes".green
        elsif project.empty_repo?
          puts "can't create, repository is empty".magenta
        else
          puts "no".red
          try_fixing_it(
            "sudo -u gitlab -H bundle exec rake gitlab:satellites:create RAILS_ENV=production",
            "If necessary, remove the tmp/repo_satellites directory ...",
            "... and rerun the above command"
          )
          for_more_information(
            "doc/raketasks/maintenance.md "
          )
          fix_and_rerun
        end
>>>>>>> gitlabhq/4-0-stable
      end
    end

    def check_log_writable
      print "Log directory writable? ... "

      log_path = Rails.root.join("log")

      if File.writable?(log_path)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo chown -R gitlab #{log_path}",
          "sudo chmod -R u+rwX #{log_path}"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        fix_and_rerun
      end
    end

    def check_tmp_writable
      print "Tmp directory writable? ... "

      tmp_path = Rails.root.join("tmp")

      if File.writable?(tmp_path)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo chown -R gitlab #{tmp_path}",
          "sudo chmod -R u+rwX #{tmp_path}"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        fix_and_rerun
      end
    end
<<<<<<< HEAD
=======
  end



  namespace :env do
    desc "GITLAB | Check the configuration of the environment"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "Environment"

      check_gitlab_in_git_group
      check_issue_1059_shell_profile_error
      check_gitlab_git_config
      check_python2_exists
      check_python2_version

      finished_checking "Environment"
    end


    # Checks
    ########################

    def check_gitlab_git_config
      print "Git configured for gitlab user? ... "
>>>>>>> gitlabhq/4-0-stable

    def check_uploads
      print "Uploads directory setup correctly? ... "

      unless File.directory?(Rails.root.join('public/uploads'))
        puts "no".red
        try_fixing_it(
          "sudo -u #{gitlab_user} mkdir -m 750 #{Rails.root}/public/uploads"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        fix_and_rerun
<<<<<<< HEAD
<<<<<<< HEAD
        return
      end

      upload_path = File.realpath(Rails.root.join('public/uploads'))
      upload_path_tmp = File.join(upload_path, 'tmp')
=======
=======
>>>>>>> origin/4-0-stable
      end
    end

    def check_gitlab_in_git_group
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user
      print "gitlab user is in #{gitolite_ssh_user} group? ... "

      if run_and_match("id -rnG", /\Wgit\W/)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo usermod -a -G #{gitolite_ssh_user} gitlab"
        )
        for_more_information(
          see_installation_guide_section "System Users"
        )
        fix_and_rerun
      end
    end

    # see https://github.com/gitlabhq/gitlabhq/issues/1059
    def check_issue_1059_shell_profile_error
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user
      print "Has no \"-e\" in ~#{gitolite_ssh_user}/.profile ... "

      profile_file = File.join(gitolite_user_home, ".profile")

      unless File.read(profile_file) =~ /^-e PATH/
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Open #{profile_file}",
          "Find the line starting with \"-e PATH\"",
          "Remove \"-e \" so the line starts with PATH"
        )
        for_more_information(
          see_installation_guide_section("Gitolite"),
          "https://github.com/gitlabhq/gitlabhq/issues/1059"
        )
        fix_and_rerun
      end
    end
>>>>>>> gitlabhq/4-0-stable

      if File.stat(upload_path).mode == 040750
        unless Dir.exists?(upload_path_tmp)
          puts 'skipped (no tmp uploads folder yet)'.magenta
          return
        end

        # if tmp upload dir has incorrect permissions, assume others do as well
        if File.stat(upload_path_tmp).mode == 040755 && File.owned?(upload_path_tmp) # verify drwxr-xr-x permissions
          puts "yes".green
        else
          puts "no".red
          try_fixing_it(
            "sudo chown -R #{gitlab_user} #{upload_path}",
            "sudo find #{upload_path} -type f -exec chmod 0644 {} \\;",
            "sudo find #{upload_path} -type d -not -path #{upload_path} -exec chmod 0755 {} \\;"
          )
          for_more_information(
            see_installation_guide_section "GitLab"
          )
          fix_and_rerun
        end
      else
        puts "no".red
        try_fixing_it(
          "sudo chmod 0750 #{upload_path}",
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        fix_and_rerun
      end
    end

    def check_redis_version
      min_redis_version = "2.8.0"
      print "Redis version >= #{min_redis_version}? ... "

      redis_version = run(%W(redis-cli --version))
      redis_version = redis_version.try(:match, /redis-cli (\d+\.\d+\.\d+)/)
      if redis_version &&
          (Gem::Version.new(redis_version[1]) > Gem::Version.new(min_redis_version))
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Update your redis server to a version >= #{min_redis_version}"
        )
        for_more_information(
          "gitlab-public-wiki/wiki/Trouble-Shooting-Guide in section sidekiq"
        )
        fix_and_rerun
      end
    end
  end

  namespace :gitlab_shell do
    desc "GitLab | Check the configuration of GitLab Shell"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "GitLab Shell"

      check_gitlab_shell
      check_repo_base_exists
      check_repo_base_is_not_symlink
      check_repo_base_user_and_group
      check_repo_base_permissions
      check_repos_hooks_directory_is_link
      check_gitlab_shell_self_test

      finished_checking "GitLab Shell"
    end


    # Checks
    ########################

    def check_repo_base_exists
      print "Repo base directory exists? ... "

      repo_base_path = Gitlab.config.gitlab_shell.repos_path

<<<<<<< HEAD
      if File.exists?(repo_base_path)
        puts "yes".green
      else
        puts "no".red
        puts "#{repo_base_path} is missing".red
        try_fixing_it(
          "This should have been created when setting up GitLab Shell.",
          "Make sure it's set correctly in config/gitlab.yml",
          "Make sure GitLab Shell is installed correctly."
        )
        for_more_information(
          see_installation_guide_section "GitLab Shell"
        )
        fix_and_rerun
      end
=======
      puts "yes".green
    rescue
      puts "no".red
      try_fixing_it(
        "Make sure the \"admin_uri\" is set correctly in config/gitlab.yml",
        "Try cloning it yourself with:",
        "  git clone -q #{Gitlab.config.gitolite.admin_uri} /tmp/gitolite-admin",
        "Make sure Gitolite is installed correctly."
      )
      for_more_information(
        see_installation_guide_section "Gitolite"
      )
      fix_and_rerun
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
    end

    def check_repo_base_is_not_symlink
      print "Repo base directory is a symlink? ... "

      repo_base_path = Gitlab.config.gitlab_shell.repos_path
      unless File.exists?(repo_base_path)
        puts "can't check because of previous errors".magenta
        return
      end

      unless File.symlink?(repo_base_path)
        puts "no".green
      else
        puts "yes".red
        try_fixing_it(
          "Make sure it's set to the real directory in config/gitlab.yml"
        )
        fix_and_rerun
      end
<<<<<<< HEAD
=======

      puts "yes".green
    rescue
      puts "no".red
      try_fixing_it(
        "Try committing to it yourself with:",
        "  git clone -q #{Gitlab.config.gitolite.admin_uri} /tmp/gitolite-admin",
        "  touch foo",
        "  git add foo",
        "  git commit -m \"foo\"",
        "Make sure Gitolite is installed correctly."
      )
      for_more_information(
        see_installation_guide_section "Gitolite"
      )
      fix_and_rerun
    ensure
      FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
>>>>>>> gitlabhq/4-0-stable
    end

    def check_repo_base_permissions
      print "Repo base access is drwxrws---? ... "

<<<<<<< HEAD
<<<<<<< HEAD
      repo_base_path = Gitlab.config.gitlab_shell.repos_path
      unless File.exists?(repo_base_path)
        puts "can't check because of previous errors".magenta
        return
      end
=======
      gitolite_config_path = File.join(gitolite_user_home, ".gitolite")
>>>>>>> gitlabhq/4-0-stable
=======
      gitolite_config_path = File.join(gitolite_user_home, ".gitolite")
>>>>>>> origin/4-0-stable

      if File.stat(repo_base_path).mode.to_s(8).ends_with?("2770")
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo chmod -R ug+rwX,o-rwx #{repo_base_path}",
          "sudo chmod -R ug-s #{repo_base_path}",
          "find #{repo_base_path} -type d -print0 | sudo xargs -0 chmod g+s"
        )
        for_more_information(
          see_installation_guide_section "GitLab Shell"
        )
        fix_and_rerun
      end
    end

    def check_repo_base_user_and_group
      gitlab_shell_ssh_user = Gitlab.config.gitlab_shell.ssh_user
      gitlab_shell_owner_group = Gitlab.config.gitlab_shell.owner_group
      print "Repo base owned by #{gitlab_shell_ssh_user}:#{gitlab_shell_owner_group}? ... "

<<<<<<< HEAD
<<<<<<< HEAD
      repo_base_path = Gitlab.config.gitlab_shell.repos_path
      unless File.exists?(repo_base_path)
=======
=======
>>>>>>> origin/4-0-stable
      gitolite_config_path = File.join(gitolite_user_home, ".gitolite")
      unless File.exists?(gitolite_config_path)
>>>>>>> gitlabhq/4-0-stable
        puts "can't check because of previous errors".magenta
        return
      end

<<<<<<< HEAD
<<<<<<< HEAD
      uid = uid_for(gitlab_shell_ssh_user)
      gid = gid_for(gitlab_shell_owner_group)
      if File.stat(repo_base_path).uid == uid && File.stat(repo_base_path).gid == gid
=======
      if File.stat(gitolite_config_path).mode.to_s(8).ends_with?("750")
>>>>>>> gitlabhq/4-0-stable
=======
      if File.stat(gitolite_config_path).mode.to_s(8).ends_with?("750")
>>>>>>> origin/4-0-stable
        puts "yes".green
      else
        puts "no".red
        puts "  User id for #{gitlab_shell_ssh_user}: #{uid}. Groupd id for #{gitlab_shell_owner_group}: #{gid}".blue
        try_fixing_it(
          "sudo chown -R #{gitlab_shell_ssh_user}:#{gitlab_shell_owner_group} #{repo_base_path}"
        )
        for_more_information(
          see_installation_guide_section "GitLab Shell"
        )
        fix_and_rerun
      end
    end

    def check_repos_hooks_directory_is_link
      print "hooks directories in repos are links: ... "

<<<<<<< HEAD
      gitlab_shell_hooks_path = Gitlab.config.gitlab_shell.hooks_path

<<<<<<< HEAD
      unless Project.count > 0
        puts "can't check, you have no projects".magenta
=======
=======
>>>>>>> origin/4-0-stable
      gitolite_config_path = File.join(gitolite_user_home, ".gitolite")
      unless File.exists?(gitolite_config_path)
        puts "can't check because of previous errors".magenta
>>>>>>> gitlabhq/4-0-stable
        return
      end
      puts ""

<<<<<<< HEAD
<<<<<<< HEAD
      Project.find_each(batch_size: 100) do |project|
        print sanitized_message(project)
        project_hook_directory = File.join(project.repository.path_to_repo, "hooks")

        if project.empty_repo?
          puts "repository is empty".magenta
        elsif File.directory?(project_hook_directory) && File.directory?(gitlab_shell_hooks_path) &&
            (File.realpath(project_hook_directory) == File.realpath(gitlab_shell_hooks_path))
          puts 'ok'.green
        else
          puts "wrong or missing hooks".red
          try_fixing_it(
            sudo_gitlab("#{File.join(gitlab_shell_path, 'bin/create-hooks')}"),
            'Check the hooks_path in config/gitlab.yml',
            'Check your gitlab-shell installation'
          )
          for_more_information(
            see_installation_guide_section "GitLab Shell"
          )
          fix_and_rerun
        end

      end
    end

    def check_gitlab_shell_self_test
      gitlab_shell_repo_base = gitlab_shell_path
      check_cmd = File.expand_path('bin/check', gitlab_shell_repo_base)
      puts "Running #{check_cmd}"
      if system(check_cmd, chdir: gitlab_shell_repo_base)
        puts 'gitlab-shell self-check successful'.green
      else
        puts 'gitlab-shell self-check failed'.red
=======
=======
>>>>>>> origin/4-0-stable
      if File.stat(gitolite_config_path).uid == uid_for(gitolite_ssh_user) &&
         File.stat(gitolite_config_path).gid == gid_for(gitolite_ssh_user)
        puts "yes".green
      else
        puts "no".red
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
        try_fixing_it(
          'Make sure GitLab is running;',
          'Check the gitlab-shell configuration file:',
          sudo_gitlab("editor #{File.expand_path('config.yml', gitlab_shell_repo_base)}")
        )
<<<<<<< HEAD
=======
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
        fix_and_rerun
      end
    end

<<<<<<< HEAD
    def check_projects_have_namespace
      print "projects have namespace: ... "

      unless Project.count > 0
        puts "can't check, you have no projects".magenta
        return
      end
      puts ""

      Project.find_each(batch_size: 100) do |project|
        print sanitized_message(project)

        if project.namespace
          puts "yes".green
        else
          puts "no".red
          try_fixing_it(
            "Migrate global projects"
          )
          for_more_information(
            "doc/update/5.4-to-6.0.md in section \"#global-projects\""
          )
          fix_and_rerun
        end
=======
        fix_and_rerun
>>>>>>> origin/4-0-stable
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



  namespace :sidekiq do
    desc "GitLab | Check the configuration of Sidekiq"
    task check: :environment  do
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
=======
    def check_gitolite_is_up_to_date
      print "Using recommended version ... "
      if gitolite_version.try(:start_with?, "v3.2")
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
        puts "yes".green
      else
        puts "no".red
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

<<<<<<< HEAD
    def only_one_sidekiq_running
      process_count = sidekiq_process_count
      return if process_count.zero?

      print 'Number of Sidekiq processes ... '
      if process_count == 1
        puts '1'.green
=======
    def check_gitoliterc_git_config_keys
      gitoliterc_path = File.join(gitolite_user_home, ".gitolite.rc")

      print "Allow all Git config keys in .gitolite.rc ... "
      option_name = if has_gitolite3?
                      # see https://github.com/sitaramc/gitolite/blob/v3.04/src/lib/Gitolite/Rc.pm#L329
                      "GIT_CONFIG_KEYS"
                    else
                      # assume older version
                      # see https://github.com/sitaramc/gitolite/blob/v2.3/conf/example.gitolite.rc#L49
                      "\\$GL_GITCONFIG_KEYS"
                    end
      option_value = ".*"
      if open(gitoliterc_path).grep(/#{option_name}\s*=[>]?\s*["']#{option_value}["']/).any?
        puts "yes".green
>>>>>>> gitlabhq/4-0-stable
      else
        puts "#{process_count}".red
        try_fixing_it(
          'sudo service gitlab stop',
          "sudo pkill -u #{gitlab_user} -f sidekiq",
          "sleep 10 && sudo pkill -9 -u #{gitlab_user} -f sidekiq",
          'sudo service gitlab start'
        )
<<<<<<< HEAD
=======
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
>>>>>>> origin/4-0-stable
        fix_and_rerun
      end
    end

<<<<<<< HEAD
    def sidekiq_process_count
      ps_ux, _ = Gitlab::Popen.popen(%W(ps ux))
      ps_ux.scan(/sidekiq \d+\.\d+\.\d+/).count
    end
  end


  namespace :incoming_email do
    desc "GitLab | Check the configuration of Reply by email"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "Reply by email"

      if Gitlab.config.incoming_email.enabled
        check_address_formatted_correctly
        check_imap_authentication

        if Rails.env.production?
          check_initd_configured_correctly
          check_mail_room_running
        else
          check_foreman_configured_correctly
        end
      else
        puts 'Reply by email is disabled in config/gitlab.yml'
=======
    def check_gitoliterc_repo_umask
      gitoliterc_path = File.join(gitolite_user_home, ".gitolite.rc")

      print "Repo umask is 0007 in .gitolite.rc? ... "
      option_name = if has_gitolite3?
                      # see https://github.com/sitaramc/gitolite/blob/v3.04/src/lib/Gitolite/Rc.pm#L328
                      "UMASK"
                    else
                      # assume older version
                      # see https://github.com/sitaramc/gitolite/blob/v2.3/conf/example.gitolite.rc#L32
                      "\\$REPO_UMASK"
                    end
      option_value = "0007"
      if open(gitoliterc_path).grep(/#{option_name}\s*=[>]?\s*#{option_value}/).any?
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Open #{gitoliterc_path}",
          "Find the \"#{option_name}\" option",
          "Change its value to \"0007\""
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        fix_and_rerun
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
      end

      finished_checking "Reply by email"
    end


    # Checks
    ########################

    def check_address_formatted_correctly
      print "Address formatted correctly? ... "

      if Gitlab::IncomingEmail.address_formatted_correctly?
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Make sure that the address in config/gitlab.yml includes the '%{key}' placeholder."
        )
<<<<<<< HEAD
=======
        for_more_information(
          see_installation_guide_section "Setup GitLab Hooks"
        )
>>>>>>> origin/4-0-stable
        fix_and_rerun
      end
    end

    def check_initd_configured_correctly
      print "Init.d configured correctly? ... "

      if omnibus_gitlab?
        puts 'skipped (omnibus-gitlab has no init script)'.magenta
        return
      end

      path = "/etc/default/gitlab"

      if File.exist?(path) && File.read(path).include?("mail_room_enabled=true")
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Enable mail_room in the init.d configuration."
        )
        for_more_information(
          "doc/incoming_email/README.md"
        )
        fix_and_rerun
      end
    end

    def check_foreman_configured_correctly
      print "Foreman configured correctly? ... "

      path = Rails.root.join("Procfile")

      if File.exist?(path) && File.read(path) =~ /^mail_room:/
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Enable mail_room in your Procfile."
        )
        for_more_information(
          "doc/incoming_email/README.md"
        )
        fix_and_rerun
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
      end
    end

    def check_repo_base_is_not_symlink
      print "Repo base directory is a symlink? ... "

      repo_base_path = Gitlab.config.gitolite.repos_path
      unless File.exists?(repo_base_path)
        puts "can't check because of previous errors".magenta
        return
      end

      unless File.symlink?(repo_base_path)
        puts "no".green
      else
        puts "yes".red
        try_fixing_it(
          "Make sure it's set to the real directory in config/gitlab.yml"
        )
        fix_and_rerun
>>>>>>> origin/4-0-stable
      end
    end

    def check_repo_base_is_not_symlink
      print "Repo base directory is a symlink? ... "

      repo_base_path = Gitlab.config.gitolite.repos_path
      unless File.exists?(repo_base_path)
        puts "can't check because of previous errors".magenta
        return
      end

<<<<<<< HEAD
      unless File.symlink?(repo_base_path)
        puts "no".green
      else
        puts "yes".red
        try_fixing_it(
          "Make sure it's set to the real directory in config/gitlab.yml"
        )
        fix_and_rerun
>>>>>>> gitlabhq/4-0-stable
      end
    end

    def check_mail_room_running
      print "MailRoom running? ... "

      path = "/etc/default/gitlab"

      unless File.exist?(path) && File.read(path).include?("mail_room_enabled=true")
        puts "can't check because of previous errors".magenta
        return
      end

<<<<<<< HEAD
      if mail_room_running?
=======
      if File.stat(repo_base_path).mode.to_s(8).ends_with?("6770")
>>>>>>> gitlabhq/4-0-stable
=======
      if File.stat(repo_base_path).mode.to_s(8).ends_with?("6770")
>>>>>>> origin/4-0-stable
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          sudo_gitlab("RAILS_ENV=production bin/mail_room start")
        )
        for_more_information(
          see_installation_guide_section("Install Init Script"),
          "see log/mail_room.log for possible errors"
        )
        fix_and_rerun
      end
    end

    def check_imap_authentication
      print "IMAP server credentials are correct? ... "

      config = Gitlab.config.incoming_email

      if config
        begin
          imap = Net::IMAP.new(config.host, port: config.port, ssl: config.ssl)
          imap.starttls if config.start_tls
          imap.login(config.user, config.password)
          connected = true
        rescue
          connected = false
        end
      end

<<<<<<< HEAD
<<<<<<< HEAD
      if connected
=======
      if File.stat(repo_base_path).uid == uid_for(gitolite_ssh_user) &&
         File.stat(repo_base_path).gid == gid_for(gitolite_ssh_user)
>>>>>>> gitlabhq/4-0-stable
=======
      if File.stat(repo_base_path).uid == uid_for(gitolite_ssh_user) &&
         File.stat(repo_base_path).gid == gid_for(gitolite_ssh_user)
>>>>>>> origin/4-0-stable
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Check that the information in config/gitlab.yml is correct"
        )
        for_more_information(
          "doc/incoming_email/README.md"
        )
        fix_and_rerun
      end
    end

<<<<<<< HEAD
    def mail_room_running?
      ps_ux, _ = Gitlab::Popen.popen(%W(ps ux))
      ps_ux.include?("mail_room")
=======
    def check_repos_git_config
      print "Git config in repos: ... "

      unless Project.count > 0
        puts "can't check, you have no projects".magenta
        return
      end
      puts ""

      options = {
        "core.sharedRepository" => "0660",
      }

      Project.find_each(batch_size: 100) do |project|
        print "#{project.name_with_namespace.yellow} ... "

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        correct_options = options.map do |name, value|
          run("git --git-dir=\"#{project.path_to_repo}\" config --get #{name}").try(:chomp) == value
        end

        if correct_options.all?
          puts "ok".green
        else
          puts "wrong or missing".red
          try_fixing_it(
            "sudo -u gitlab -H bundle exec rake gitlab:gitolite:update_repos RAILS_ENV=production"
          )
          for_more_information(
            "doc/raketasks/maintenance.md"
          )
          fix_and_rerun
=======
        if project.empty_repo?
          puts "repository is empty".magenta
        else
=======
        if project.empty_repo?
          puts "repository is empty".magenta
        else
>>>>>>> gitlabhq/4-1-stable
=======
        if project.empty_repo?
          puts "repository is empty".magenta
        else
>>>>>>> origin/4-1-stable
          correct_options = options.map do |name, value|
            run("git --git-dir=\"#{project.repository.path_to_repo}\" config --get #{name}").try(:chomp) == value
          end

          if correct_options.all?
            puts "ok".green
          else
            puts "wrong or missing".red
            try_fixing_it(
              sudo_gitlab("bundle exec rake gitlab:gitolite:update_repos")
            )
            for_more_information(
              "doc/raketasks/maintenance.md"
            )
            fix_and_rerun
          end
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> gitlabhq/4-1-stable
=======
>>>>>>> gitlabhq/4-1-stable
=======
>>>>>>> origin/4-1-stable
        end
      end
>>>>>>> gitlabhq/4-0-stable
    end
  end

  namespace :ldap do
    task :check, [:limit] => :environment do |t, args|
      # Only show up to 100 results because LDAP directories can be very big.
      # This setting only affects the `rake gitlab:check` script.
      args.with_defaults(limit: 100)
      warn_user_is_not_gitlab
      start_checking "LDAP"

      if Gitlab::LDAP::Config.enabled?
        print_users(args.limit)
      else
        puts 'LDAP is disabled in config/gitlab.yml'
      end

<<<<<<< HEAD
<<<<<<< HEAD
      finished_checking "LDAP"
    end

<<<<<<< HEAD
    def print_users(limit)
      puts "LDAP users with access to your GitLab server (only showing the first #{limit} results)"

<<<<<<< HEAD
      servers = Gitlab::LDAP::Config.providers

      servers.each do |server|
        puts "Server: #{server}"
        Gitlab::LDAP::Adapter.open(server) do |adapter|
          users = adapter.users(adapter.config.uid, '*', 100)
          users.each do |user|
            puts "\tDN: #{user.dn}\t #{adapter.config.uid}: #{user.uid}"
          end
=======
        unless File.exists?(project_hook_file)
          puts "missing".red
          try_fixing_it(
            "sudo -u #{gitolite_ssh_user} ln -sf #{gitolite_hook_file} #{project_hook_file}"
          )
          for_more_information(
            "lib/support/rewrite-hooks.sh"
          )
          fix_and_rerun
          next
        end

        if File.lstat(project_hook_file).symlink? &&
            File.realpath(project_hook_file) == File.realpath(gitolite_hook_file)
          puts "ok".green
        else
          puts "not a link to Gitolite's hook".red
          try_fixing_it(
            "sudo -u #{gitolite_ssh_user} ln -sf #{gitolite_hook_file} #{project_hook_file}"
          )
          for_more_information(
            "lib/support/rewrite-hooks.sh"
          )
          fix_and_rerun
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
=======
      Project.find_each(batch_size: 100) do |project|
        print "#{project.name_with_namespace.yellow} ... "

        if project.empty_repo?
          puts "repository is empty".magenta
        else
=======
      Project.find_each(batch_size: 100) do |project|
        print "#{project.name_with_namespace.yellow} ... "

        if project.empty_repo?
          puts "repository is empty".magenta
        else
>>>>>>> gitlabhq/4-1-stable
=======
      Project.find_each(batch_size: 100) do |project|
        print "#{project.name_with_namespace.yellow} ... "

        if project.empty_repo?
          puts "repository is empty".magenta
        else
>>>>>>> origin/4-1-stable
          project_hook_file = File.join(project.repository.path_to_repo, "hooks", hook_file)

          unless File.exists?(project_hook_file)
            puts "missing".red
            try_fixing_it(
              "sudo -u #{gitolite_ssh_user} ln -sf #{gitolite_hook_file} #{project_hook_file}"
            )
            for_more_information(
              "lib/support/rewrite-hooks.sh"
            )
            fix_and_rerun
            next
          end

          if File.lstat(project_hook_file).symlink? &&
              File.realpath(project_hook_file) == File.realpath(gitolite_hook_file)
            puts "ok".green
          else
            puts "not a link to Gitolite's hook".red
            try_fixing_it(
              "sudo -u #{gitolite_ssh_user} ln -sf #{gitolite_hook_file} #{project_hook_file}"
            )
            for_more_information(
              "lib/support/rewrite-hooks.sh"
            )
            fix_and_rerun
          end
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> gitlabhq/4-1-stable
=======
>>>>>>> gitlabhq/4-1-stable
=======
>>>>>>> origin/4-1-stable
        end
      end
    end
  end

  namespace :repo do
    desc "GitLab | Check the integrity of the repositories managed by GitLab"
    task check: :environment do
      namespace_dirs = Dir.glob(
        File.join(Gitlab.config.gitlab_shell.repos_path, '*')
      )

<<<<<<< HEAD
      namespace_dirs.each do |namespace_dir|
        repo_dirs = Dir.glob(File.join(namespace_dir, '*'))
        repo_dirs.each { |repo_dir| check_repo_integrity(repo_dir) }
=======
    # Helper methods
    ########################

    def gitolite_user_home
      File.expand_path("~#{Gitlab.config.gitolite.ssh_user}")
    end

    def gitolite_version
      gitolite_version_file = "#{gitolite_user_home}/gitolite/src/VERSION"
      if File.readable?(gitolite_version_file)
        File.read(gitolite_version_file)
>>>>>>> gitlabhq/4-0-stable
      end
    end
  end

<<<<<<< HEAD
  namespace :user do
    desc "GitLab | Check the integrity of a specific user's repositories"
    task :check_repos, [:username] => :environment do |t, args|
      username = args[:username] || prompt("Check repository integrity for which username? ".blue)
      user = User.find_by(username: username)
      if user
        repo_dirs = user.authorized_projects.map do |p|
                      File.join(
                        Gitlab.config.gitlab_shell.repos_path,
                        "#{p.path_with_namespace}.git"
                      )
                    end

        repo_dirs.each { |repo_dir| check_repo_integrity(repo_dir) }
=======


  namespace :sidekiq do
    desc "GITLAB | Check the configuration of Sidekiq"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "Sidekiq"

      check_sidekiq_running

      finished_checking "Sidekiq"
    end


    # Checks
    ########################

    def check_sidekiq_running
      print "Running? ... "

      if run_and_match("ps aux | grep -i sidekiq", /sidekiq \d+\.\d+\.\d+.+$/)
        puts "yes".green
>>>>>>> gitlabhq/5-2-stable
      else
<<<<<<< HEAD
        puts "\nUser '#{username}' not found".red
=======
        puts "no".red
        try_fixing_it(
          "sudo service gitlab restart",
          "or",
          "sudo /etc/init.d/gitlab restart"
        )
        for_more_information(
          see_installation_guide_section("Install Init Script"),
          "see log/resque.log for possible errors"
        )
        fix_and_rerun
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
      end
    end
  end

  # Helper methods
  ##########################

  def fix_and_rerun
    puts "  Please #{"fix the error above"} and rerun the checks.".red
  end

  def for_more_information(*sources)
    sources = sources.shift if sources.first.is_a?(Array)

    puts "  For more information see:".blue
    sources.each do |source|
      puts "  #{source}"
    end
  end

  def finished_checking(component)
    puts ""
    puts "Checking #{component.yellow} ... #{"Finished".green}"
    puts ""
  end

  def see_database_guide
    "doc/install/databases.md"
  end

  def see_installation_guide_section(section)
    "doc/install/installation.md in section \"#{section}\""
  end

  def sudo_gitlab(command)
    "sudo -u #{gitlab_user} -H #{command}"
  end

  def gitlab_user
    Gitlab.config.gitlab.user
  end

  def start_checking(component)
    puts "Checking #{component.yellow} ..."
    puts ""
  end

  def try_fixing_it(*steps)
    steps = steps.shift if steps.first.is_a?(Array)

    puts "  Try fixing it:".blue
    steps.each do |step|
      puts "  #{step}"
    end
  end
<<<<<<< HEAD
<<<<<<< HEAD

  def check_gitlab_shell
<<<<<<< HEAD
<<<<<<< HEAD
    required_version = Gitlab::VersionInfo.new(gitlab_shell_major_version, gitlab_shell_minor_version, gitlab_shell_patch_version)
=======
    required_version = Gitlab::VersionInfo.new(1, 7, 8)
>>>>>>> origin/5-4-stable
=======
    required_version = Gitlab::VersionInfo.new(1, 7, 8)
>>>>>>> origin/5-4-stable
    current_version = Gitlab::VersionInfo.parse(gitlab_shell_version)

    print "GitLab Shell version >= #{required_version} ? ... "
    if current_version.valid? && required_version <= current_version
      puts "OK (#{current_version})".green
    else
      puts "FAIL. Please update gitlab-shell to #{required_version} from #{current_version}".red
    end
  end

  def check_ruby_version
    required_version = Gitlab::VersionInfo.new(2, 1, 0)
    current_version = Gitlab::VersionInfo.parse(run(%W(ruby --version)))

    print "Ruby version >= #{required_version} ? ... "

    if current_version.valid? && required_version <= current_version
      puts "yes (#{current_version})".green
    else
      puts "no".red
      try_fixing_it(
        "Update your ruby to a version >= #{required_version} from #{current_version}"
      )
      fix_and_rerun
    end
  end

  def check_git_version
    required_version = Gitlab::VersionInfo.new(1, 7, 10)
    current_version = Gitlab::VersionInfo.parse(run(%W(#{Gitlab.config.git.bin_path} --version)))

    puts "Your git bin path is \"#{Gitlab.config.git.bin_path}\""
    print "Git version >= #{required_version} ? ... "

    if current_version.valid? && required_version <= current_version
      puts "yes (#{current_version})".green
    else
      puts "no".red
      try_fixing_it(
        "Update your git to a version >= #{required_version} from #{current_version}"
      )
      fix_and_rerun
    end
  end

  def check_active_users
    puts "Active users: #{User.active.count}"
  end

  def omnibus_gitlab?
    Dir.pwd == '/opt/gitlab/embedded/service/gitlab-rails'
  end

  def sanitized_message(project)
    if should_sanitize?
      "#{project.namespace_id.to_s.yellow}/#{project.id.to_s.yellow} ... "
    else
      "#{project.name_with_namespace.yellow} ... "
    end
  end

  def should_sanitize?
    if ENV['SANITIZE'] == "true"
      true
    else
      false
    end
  end

  def check_repo_integrity(repo_dir)
    puts "\nChecking repo at #{repo_dir.yellow}"

    git_fsck(repo_dir)
    check_config_lock(repo_dir)
    check_ref_locks(repo_dir)
  end

  def git_fsck(repo_dir)
    puts "Running `git fsck`".yellow
    system(*%W(#{Gitlab.config.git.bin_path} fsck), chdir: repo_dir)
  end

  def check_config_lock(repo_dir)
    config_exists = File.exist?(File.join(repo_dir,'config.lock'))
    config_output = config_exists ? 'yes'.red : 'no'.green
    puts "'config.lock' file exists?".yellow + " ... #{config_output}"
  end

  def check_ref_locks(repo_dir)
    lock_files = Dir.glob(File.join(repo_dir,'refs/heads/*.lock'))
    if lock_files.present?
      puts "Ref lock files exist:".red
      lock_files.each do |lock_file|
        puts "  #{lock_file}"
      end
    else
      puts "No ref lock files exist".green
    end
  end
=======
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
end
