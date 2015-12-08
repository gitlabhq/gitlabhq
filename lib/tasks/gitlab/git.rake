namespace :gitlab do
  namespace :git do

    desc "GitLab | Git | Repack"
    task repack: :environment do
      failures = perform_git_cmd(%W(git repack -a --quiet), "Repacking repo")
      if failures.empty?
        puts "Done".green
      else
        output_failures(failures)
      end
    end

    desc "GitLab | Git | Run garbage collection on all repos"
    task gc: :environment do
      failures = perform_git_cmd(%W(git gc --auto --quiet), "Garbage Collecting")
      if failures.empty?
        puts "Done".green
      else
        output_failures(failures)
      end
    end
    
    desc "GitLab | Git | Prune all repos"
    task prune: :environment do
      failures = perform_git_cmd(%W(git prune), "Git Prune")
      if failures.empty?
        puts "Done".green
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
      end

      failures
    end

    def output_failures(failures)
      puts "The following repositories reported errors:".red
      failures.each { |f| puts "- #{f}" }
    end

  end
end
