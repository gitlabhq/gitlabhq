namespace :gitlab do
  namespace :shell do
    desc "GitLab | Install or upgrade gitlab-shell"
    task :install, [:tag, :repo] => :environment do |t, args|
      warn_user_is_not_gitlab

      default_version = Gitlab::Shell.version_required
      args.with_defaults(tag: 'v' + default_version, repo: "https://gitlab.com/gitlab-org/gitlab-shell.git")

      user = Gitlab.config.gitlab.user
      home_dir = Rails.env.test? ? Rails.root.join('tmp/tests') : Gitlab.config.gitlab.user_home
      gitlab_url = Gitlab.config.gitlab.url
      # gitlab-shell requires a / at the end of the url
      gitlab_url += '/' unless gitlab_url.end_with?('/')
      repos_path = Gitlab.config.gitlab_shell.repos_path
      target_dir = Gitlab.config.gitlab_shell.path

      # Clone if needed
      unless File.directory?(target_dir)
        system(*%W(#{Gitlab.config.git.bin_path} clone -- #{args.repo} #{target_dir}))
      end

      # Make sure we're on the right tag
      Dir.chdir(target_dir) do
        # First try to checkout without fetching
        # to avoid stalling tests if the Internet is down.
        reseted = reset_to_commit(args)

        unless reseted
          system(*%W(#{Gitlab.config.git.bin_path} fetch origin))
          reset_to_commit(args)
        end

        config = {
          user: user,
          gitlab_url: gitlab_url,
          http_settings: {self_signed_cert: false}.stringify_keys,
          repos_path: repos_path,
          auth_file: File.join(home_dir, ".ssh", "authorized_keys"),
          redis: {
            bin: %x{which redis-cli}.chomp,
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

        # Launch installation process
        system(*%W(bin/install))

        # (Re)create hooks
        system(*%W(bin/create-hooks))
      end

      # Required for debian packaging with PKGR: Setup .ssh/environment with
      # the current PATH, so that the correct ruby version gets loaded
      # Requires to set "PermitUserEnvironment yes" in sshd config (should not
      # be an issue since it is more than likely that there are no "normal"
      # user accounts on a gitlab server). The alternative is for the admin to
      # install a ruby (1.9.3+) in the global path.
      File.open(File.join(home_dir, ".ssh", "environment"), "w+") do |f|
        f.puts "PATH=#{ENV['PATH']}"
      end
    end

    desc "GitLab | Setup gitlab-shell"
    task setup: :environment do
      setup
    end

    desc "GitLab | Build missing projects"
    task build_missing_projects: :environment do
      Project.find_each(batch_size: 1000) do |project|
        path_to_repo = project.repository.path_to_repo
        if File.exists?(path_to_repo)
          print '-'
        else
          if Gitlab::Shell.new.add_repository(project.path_with_namespace)
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
      puts "Failed to add keys...".red
      exit 1
    end

  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".red
    exit 1
  end

  def reset_to_commit(args)
    tag, status = Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} describe -- #{args.tag}))

    unless status.zero?
      tag, status = Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} describe -- origin/#{args.tag}))
    end

    tag = tag.strip
    system(*%W(#{Gitlab.config.git.bin_path} reset --hard #{tag}))
  end
end

