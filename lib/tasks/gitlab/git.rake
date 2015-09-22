namespace :gitlab do
  namespace :git do

    desc "GitLab | Git | Repack"
    task repack: :environment do
      failures = perform_git_cmd('git repack -a --quiet', 'Git repack')
      if failures.empty?
        puts "Done".green
      else
        output_failures(failures)
      end
    end

    desc "GitLab | Git | Run gits garbage collection on all repo's"
    task gc: :environment do
      failures = perform_git_cmd('git gc --auto --quiet', "Garbage Collection")
      if failures.empty?
        puts "Done".green
      else
        output_failures(failures)
      end
    end
    
    desc "GitLab | Git | Git prune all repo's"
    task prune: :environment do
      failures = perform_git_cmd('git prune', 'Git Prune')
      if failures.empty?
        puts "Done".green
      else
        output_failures(failures)
      end
    end

    def perform_git_cmd(cmd, message)
      puts "Starting #{message} on all repositories"

      failures = []
      all_repos.each do |r|
        puts "Performing #{message} at #{r}"
        failures << r unless system(*%w(#{cmd}), chdir: r)
      end

      failures
    end

    def output_failures(failures)
      puts "The following repositories reported errors:".red
      failures.each { |f| puts "- #{f}" }
    end

  end
end
