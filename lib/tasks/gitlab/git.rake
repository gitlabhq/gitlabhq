namespace :gitlab do
  namespace :git do
    desc "GitLab | Git | Repack"
    task repack: :gitlab_environment do
      failures = perform_git_cmd(%W(#{Gitlab.config.git.bin_path} repack -a --quiet), "Repacking repo")
      if failures.empty?
        puts "Done".color(:green)
      else
        output_failures(failures)
      end
    end

    desc "GitLab | Git | Run garbage collection on all repos"
    task gc: :gitlab_environment do
      failures = perform_git_cmd(%W(#{Gitlab.config.git.bin_path} gc --auto --quiet), "Garbage Collecting")
      if failures.empty?
        puts "Done".color(:green)
      else
        output_failures(failures)
      end
    end

    desc "GitLab | Git | Prune all repos"
    task prune: :gitlab_environment do
      failures = perform_git_cmd(%W(#{Gitlab.config.git.bin_path} prune), "Git Prune")
      if failures.empty?
        puts "Done".color(:green)
      else
        output_failures(failures)
      end
    end

    desc 'GitLab | Git | Check all repos integrity'
    task fsck: :gitlab_environment do
      failures = perform_git_cmd(%W(#{Gitlab.config.git.bin_path} fsck --name-objects --no-progress), "Checking integrity") do |repo|
        check_config_lock(repo)
        check_ref_locks(repo)
      end

      if failures.empty?
        puts "Done".color(:green)
      else
        output_failures(failures)
      end
    end

    def perform_git_cmd(cmd, message)
      puts "Starting #{message} on all repositories"

      failures = []
      all_repos do |repo|
        if system(*cmd, chdir: repo)
          puts "Performed #{message} at #{repo}"
        else
          failures << repo
        end

        yield(repo) if block_given?
      end

      failures
    end

    def output_failures(failures)
      puts "The following repositories reported errors:".color(:red)
      failures.each { |f| puts "- #{f}" }
    end

    def check_config_lock(repo_dir)
      config_exists = File.exist?(File.join(repo_dir, 'config.lock'))
      config_output = config_exists ? 'yes'.color(:red) : 'no'.color(:green)

      puts "'config.lock' file exists?".color(:yellow) + " ... #{config_output}"
    end

    def check_ref_locks(repo_dir)
      lock_files = Dir.glob(File.join(repo_dir, 'refs/heads/*.lock'))

      if lock_files.present?
        puts "Ref lock files exist:".color(:red)

        lock_files.each { |lock_file| puts "  #{lock_file}" }
      else
        puts "No ref lock files exist".color(:green)
      end
    end
  end
end
