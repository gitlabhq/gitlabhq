namespace :gitlab do
  desc "GITLAB | Check the configuration of GitLab and its environment"
  task check: %w{gitlab:env:check
                 gitlab:gitolite:check
                 gitlab:resque:check
                 gitlab:app:check}



  namespace :app do
    desc "GITLAB | Check the configuration of the GitLab Rails app"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "GitLab"

      check_database_config_exists
      check_database_is_not_sqlite
      check_migrations_are_up
      check_gitlab_config_exists
      check_gitlab_config_not_outdated
      check_log_writable
      check_tmp_writable
      check_init_script_exists
      check_init_script_up_to_date
      check_satellites_exist

      finished_checking "GitLab"
    end


    # Checks
    ########################

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
        check_failed
      end
    end

    def check_database_is_not_sqlite
      print "Database is not SQLite ... "

      database_config_file = Rails.root.join("config", "database.yml")

      unless File.read(database_config_file) =~ /sqlite/
        puts "yes".green
      else
        puts "no".red
        for_more_information(
          "https://github.com/gitlabhq/gitlabhq/wiki/Migrate-from-SQLite-to-MySQL",
          see_database_guide
        )
        check_failed
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
        check_failed
      end
    end

    def check_gitlab_config_not_outdated
      print "GitLab config outdated? ... "

      gitlab_config_file = Rails.root.join("config", "gitlab.yml")
      unless File.exists?(gitlab_config_file)
        puts "can't check because of previous errors".magenta
      end

      # omniauth or ldap could have been deleted from the file
      unless Gitlab.config.pre_40_config
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
        check_failed
      end
    end

    def check_init_script_exists
      print "Init script exists? ... "

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
        check_failed
      end
    end

    def check_init_script_up_to_date
      print "Init script up-to-date? ... "

      script_path = "/etc/init.d/gitlab"
      unless File.exists?(script_path)
        puts "can't check because of previous errors".magenta
        return
      end

      recipe_content = `curl https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab 2>/dev/null`
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
        check_failed
      end
    end

    def check_migrations_are_up
      print "All migrations up? ... "

      migration_status =  `bundle exec rake db:migrate:status`

      unless migration_status =~ /down\s+\d{14}/
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo -u gitlab -H bundle exec rake db:migrate"
        )
        check_failed
      end
    end

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
        else
          puts "no".red
          try_fixing_it(
            "sudo -u gitlab -H bundle exec rake gitlab:satellites:create",
            "If necessary, remove the tmp/repo_satellites directory ...",
            "... and rerun the above command"
          )
          for_more_information(
            "doc/raketasks/maintenance.md "
          )
          check_failed
        end
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
          "sudo chmod -R rwX #{log_path}"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        check_failed
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
          "sudo chmod -R rwX #{tmp_path}"
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        check_failed
      end
    end
  end



  namespace :env do
    desc "GITLAB | Check the configuration of the environment"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "Environment"

      check_gitlab_in_git_group
      check_issue_1056_shell_profile_error
      check_gitlab_git_config
      check_python2_exists
      check_python2_version

      finished_checking "Environment"
    end


    # Checks
    ########################

    def check_gitlab_git_config
      print "Git configured for gitlab user? ... "

      options = {
        "user.name"  => "GitLab",
        "user.email" => Gitlab.config.gitlab.email_from
      }
      correct_options = options.map do |name, value|
        run("git config --global --get #{name}").try(:squish) == value
      end

      if correct_options.all?
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo -u gitlab -H git config --global user.name  \"#{options["user.name"]}\"",
          "sudo -u gitlab -H git config --global user.email \"#{options["user.email"]}\""
        )
        for_more_information(
          see_installation_guide_section "GitLab"
        )
        check_failed
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
        check_failed
      end
    end

    # see https://github.com/gitlabhq/gitlabhq/issues/1059
    def check_issue_1056_shell_profile_error
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user
      print "Has no \"-e\" in ~#{gitolite_ssh_user}/.profile ... "

      profile_file = File.expand_path("~#{Gitlab.config.gitolite.ssh_user}/.profile")

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
        check_failed
      end
    end

    def check_python2_exists
      print "Has python2? ... "

      # Python prints its version to STDERR
      # so we can't just use run("python2 --version")
      if run_and_match("which python2", /python2$/)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Make sure you have Python 2.5+ installed",
          "Link it to python2"
        )
        for_more_information(
          see_installation_guide_section "Packages / Dependencies"
        )
        check_failed
      end
    end

    def check_python2_version
      print "python2 is supported version? ... "

      # Python prints its version to STDERR
      # so we can't just use run("python2 --version")

      unless run_and_match("which python2", /python2$/)
        puts "can't check because of previous errors".magenta
        return
      end

      if `python2 --version 2>&1` =~ /2\.[567]\.\d/
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Make sure you have Python 2.5+ installed",
          "Link it to python2"
        )
        for_more_information(
          see_installation_guide_section "Packages / Dependencies"
        )
        check_failed
      end
    end
  end



  namespace :gitolite do
    desc "GITLAB | Check the configuration of Gitolite"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "Gitolite"

      check_gitolite_is_up_to_date
      check_gitoliterc_repo_umask
      check_gitoliterc_git_config_keys
      check_dot_gitolite_exists
      check_dot_gitolite_user_and_group
      check_dot_gitolite_permissions
      check_repo_base_exists
      check_repo_base_user_and_group
      check_repo_base_permissions
      check_can_clone_gitolite_admin
      check_can_commit_to_gitolite_admin
      check_post_receive_hook_exists
      check_post_receive_hook_is_up_to_date
      check_repos_post_receive_hooks_is_link
      check_repos_git_config

      finished_checking "Gitolite"
    end


    # Checks
    ########################

    def check_can_clone_gitolite_admin
      print "Can clone gitolite-admin? ... "

      test_path = "/tmp/gitlab_gitolite_admin_test"
      FileUtils.rm_rf(test_path)
      `git clone -q #{Gitlab.config.gitolite.admin_uri} #{test_path}`
      raise unless $?.success?

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
      check_failed
    end

    # assumes #check_can_clone_gitolite_admin has been run before
    def check_can_commit_to_gitolite_admin
      print "Can commit to gitolite-admin? ... "

      test_path = "/tmp/gitlab_gitolite_admin_test"
      unless File.exists?(test_path)
        puts "can't check because of previous errors".magenta
        return
      end

      Dir.chdir(test_path) do
        `touch foo && git add foo && git commit -qm foo`
        raise unless $?.success?
      end

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
      check_failed
    ensure
      FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
    end

    def check_dot_gitolite_exists
      print "Config directory exists? ... "

      gitolite_config_path = File.expand_path("~#{Gitlab.config.gitolite.ssh_user}/.gitolite")

      if File.directory?(gitolite_config_path)
        puts "yes".green
      else
        puts "no".red
        puts "#{gitolite_config_path} is missing".red
        try_fixing_it(
          "This should have been created when setting up Gitolite.",
          "Make sure Gitolite is installed correctly."
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

    def check_dot_gitolite_permissions
      print "Config directory access is drwxr-x---? ... "

      gitolite_config_path = File.expand_path("~#{Gitlab.config.gitolite.ssh_user}/.gitolite")
      unless File.exists?(gitolite_config_path)
        puts "can't check because of previous errors".magenta
        return
      end

      if `stat --printf %a #{gitolite_config_path}` == "750"
        puts "yes".green
      else
        puts "no".red
        puts "#{gitolite_config_path} is not writable".red
        try_fixing_it(
          "sudo chmod 750 #{gitolite_config_path}"
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

    def check_dot_gitolite_user_and_group
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user
      print "Config directory owned by #{gitolite_ssh_user}:#{gitolite_ssh_user} ... "

      gitolite_config_path = File.expand_path("~#{gitolite_ssh_user}/.gitolite")
      unless File.exists?(gitolite_config_path)
        puts "can't check because of previous errors".magenta
        return
      end

      if `stat --printf %U #{gitolite_config_path}` == gitolite_ssh_user && # user
         `stat --printf %G #{gitolite_config_path}` == gitolite_ssh_user #group
        puts "yes".green
      else
        puts "no".red
        puts "#{gitolite_config_path} is not owned by #{gitolite_ssh_user}".red
        try_fixing_it(
          "sudo chown -R #{gitolite_ssh_user}:#{gitolite_ssh_user} #{gitolite_config_path}"
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

    def check_gitolite_is_up_to_date
      print "Using recommended version ... "
      if gitolite_version.try(:start_with?, "v3.04")
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "We strongly recommend using the version pointed out in the installation guide."
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        # this is not a "hard" failure
      end
    end

    def check_gitoliterc_git_config_keys
      gitoliterc_path = File.join(gitolite_home, ".gitolite.rc")

      print "Allow all Git config keys in .gitolite.rc ... "
      option_name = if has_gitolite3?
                      # see https://github.com/sitaramc/gitolite/blob/v3.04/src/lib/Gitolite/Rc.pm#L329
                      "GIT_CONFIG_KEYS"
                    else
                      # assume older version
                      # see https://github.com/sitaramc/gitolite/blob/v2.3/conf/example.gitolite.rc#L49
                      "$GL_GITCONFIG_KEYS"
                    end
      option_value = ".*"
      if open(gitoliterc_path).grep(/#{option_name}\s*=[>]?\s*["']#{option_value}["']/).any?
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "Open #{gitoliterc_path}",
          "Find the \"#{option_name}\" option",
          "Change its value to \".*\""
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

    def check_gitoliterc_repo_umask
      gitoliterc_path = File.join(gitolite_home, ".gitolite.rc")

      print "Repo umask is 0007 in .gitolite.rc? ... "
      option_name = if has_gitolite3?
                      # see https://github.com/sitaramc/gitolite/blob/v3.04/src/lib/Gitolite/Rc.pm#L328
                      "UMASK"
                    else
                      # assume older version
                      # see https://github.com/sitaramc/gitolite/blob/v2.3/conf/example.gitolite.rc#L32
                      "$REPO_UMASK"
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
        check_failed
      end
    end

    def check_post_receive_hook_exists
      print "post-receive hook exists? ... "

      hook_file = "post-receive"
      gitolite_hooks_path = File.join(Gitlab.config.gitolite.hooks_path, "common")
      gitolite_hook_file = File.join(gitolite_hooks_path, hook_file)
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user

      gitlab_hook_file = Rails.root.join.join("lib", "hooks", hook_file)

      if File.exists?(gitolite_hook_file)
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo -u #{gitolite_ssh_user} cp #{gitlab_hook_file} #{gitolite_hook_file}"
        )
        for_more_information(
          see_installation_guide_section "Setup GitLab Hooks"
        )
        check_failed
      end
    end

    def check_post_receive_hook_is_up_to_date
      print "post-receive hook up-to-date? ... "

      hook_file = "post-receive"
      gitolite_hooks_path = File.join(Gitlab.config.gitolite.hooks_path, "common")
      gitolite_hook_file  = File.join(gitolite_hooks_path, hook_file)
      gitolite_hook_content = File.read(gitolite_hook_file)
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user

      unless File.exists?(gitolite_hook_file)
        puts "can't check because of previous errors".magenta
        return
      end

      gitlab_hook_file = Rails.root.join.join("lib", "hooks", hook_file)
      gitlab_hook_content = File.read(gitlab_hook_file)

      if gitolite_hook_content == gitlab_hook_content
        puts "yes".green
      else
        puts "no".red
        try_fixing_it(
          "sudo -u #{gitolite_ssh_user} cp #{gitlab_hook_file} #{gitolite_hook_file}"
        )
        for_more_information(
          see_installation_guide_section "Setup GitLab Hooks"
        )
        check_failed
      end
    end

    def check_repo_base_exists
      print "Repo base directory exists? ... "

      repo_base_path = Gitlab.config.gitolite.repos_path

      if File.exists?(repo_base_path)
        puts "yes".green
      else
        puts "no".red
        puts "#{repo_base_path} is missing".red
        try_fixing_it(
          "This should have been created when setting up Gitolite.",
          "Make sure it's set correctly in config/gitlab.yml",
          "Make sure Gitolite is installed correctly."
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

    def check_repo_base_permissions
      print "Repo base access is drwsrws---? ... "

      repo_base_path = Gitlab.config.gitolite.repos_path
      unless File.exists?(repo_base_path)
        puts "can't check because of previous errors".magenta
        return
      end

      if `stat --printf %a #{repo_base_path}` == "6770"
        puts "yes".green
      else
        puts "no".red
        puts "#{repo_base_path} is not writable".red
        try_fixing_it(
          "sudo chmod -R ug+rwXs,o-rwx #{repo_base_path}"
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

    def check_repo_base_user_and_group
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user
      print "Repo base owned by #{gitolite_ssh_user}:#{gitolite_ssh_user}? ... "

      repo_base_path = Gitlab.config.gitolite.repos_path
      unless File.exists?(repo_base_path)
        puts "can't check because of previous errors".magenta
        return
      end

      if `stat --printf %U #{repo_base_path}` == gitolite_ssh_user && # user
         `stat --printf %G #{repo_base_path}` == gitolite_ssh_user #group
        puts "yes".green
      else
        puts "no".red
        puts "#{repo_base_path} is not owned by #{gitolite_ssh_user}".red
        try_fixing_it(
          "sudo chown -R #{gitolite_ssh_user}:#{gitolite_ssh_user} #{repo_base_path}"
        )
        for_more_information(
          see_installation_guide_section "Gitolite"
        )
        check_failed
      end
    end

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

        correct_options = options.map do |name, value|
          run("git --git-dir=\"#{project.path_to_repo}\" config --get #{name}").try(:chomp) == value
        end

        if correct_options.all?
          puts "ok".green
        else
          puts "wrong or missing".red
          try_fixing_it(
            "sudo -u gitlab -H bundle exec rake gitlab:gitolite:update_repos"
          )
          for_more_information(
            "doc/raketasks/maintenance.md"
          )
          check_failed
        end
      end
    end

    def check_repos_post_receive_hooks_is_link
      print "post-receive hooks in repos are links: ... "

      hook_file = "post-receive"
      gitolite_hooks_path = File.join(Gitlab.config.gitolite.hooks_path, "common")
      gitolite_hook_file  = File.join(gitolite_hooks_path, hook_file)
      gitolite_ssh_user = Gitlab.config.gitolite.ssh_user

      unless File.exists?(gitolite_hook_file)
        puts "can't check because of previous errors".magenta
        return
      end

      unless Project.count > 0
        puts "can't check, you have no projects".magenta
        return
      end
      puts ""

      Project.find_each(batch_size: 100) do |project|
        print "#{project.name_with_namespace.yellow} ... "
        project_hook_file = File.join(project.path_to_repo, "hooks", hook_file)

        unless File.exists?(project_hook_file)
          puts "missing".red
          try_fixing_it(
            "sudo -u #{gitolite_ssh_user} ln -sf #{gitolite_hook_file} #{project_hook_file}"
          )
          for_more_information(
            "lib/support/rewrite-hooks.sh"
          )
          check_failed
          next
        end

        if run_and_match("stat --format %N #{project_hook_file}", /#{hook_file}.+->.+#{gitolite_hook_file}/)
          puts "ok".green
        else
          puts "not a link to Gitolite's hook".red
          try_fixing_it(
            "sudo -u #{gitolite_ssh_user} ln -sf #{gitolite_hook_file} #{project_hook_file}"
          )
          for_more_information(
            "lib/support/rewrite-hooks.sh"
          )
          check_failed
        end
      end
    end


    # Helper methods
    ########################

    def gitolite_home
      File.expand_path("~#{Gitlab.config.gitolite.ssh_user}")
    end

    def gitolite_version
      gitolite_version_file = "#{gitolite_home}/gitolite/src/VERSION"
      if File.readable?(gitolite_version_file)
        File.read(gitolite_version_file)
      end
    end

    def has_gitolite3?
      gitolite_version.try(:start_with?, "v3.")
    end
  end



  namespace :resque do
    desc "GITLAB | Check the configuration of Resque"
    task check: :environment  do
      warn_user_is_not_gitlab
      start_checking "Resque"

      check_resque_running

      finished_checking "Resque"
    end


    # Checks
    ########################

    def check_resque_running
      print "Running? ... "

      if run_and_match("ps aux | grep -i resque", /resque-[\d\.]+:.+$/)
        puts "yes".green
      else
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
        check_failed
      end
    end
  end


  # Helper methods
  ##########################

  def check_failed
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

  # Runs the given command
  #
  # Returns nil if the command was not found
  # Returns the output of the command otherwise
  #
  # see also #run_and_match
  def run(command)
    unless `#{command} 2>/dev/null`.blank?
      `#{command}`
    end
  end

  # Runs the given command and matches the output agains the given pattern
  #
  # Returns nil if nothing matched
  # Retunrs the MatchData if the pattern matched
  #
  # see also #run
  # see also String#match
  def run_and_match(command, pattern)
    run(command).try(:match, pattern)
  end

  def see_database_guide
    "doc/install/databases.md"
  end

  def see_installation_guide_section(section)
    "doc/install/installation.md in section \"#{section}\""
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

  def warn_user_is_not_gitlab
    unless @warned_user_not_gitlab
      current_user = run("whoami").chomp
      unless current_user == "gitlab"
        puts "#{Colored.color(:black)+Colored.color(:on_yellow)} Warning #{Colored.extra(:clear)}"
        puts "  You are running as user #{current_user.magenta}, we hope you know what you are doing."
        puts "  Some tests may pass\/fail for the wrong reason."
        puts "  For meaningful results you should run this as user #{"gitlab".magenta}."
        puts ""
      end
      @warned_user_not_gitlab = true
    end
  end
end
