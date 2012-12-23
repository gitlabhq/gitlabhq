namespace :gitlab do
  desc "GITLAB | Enable auto merge"
  task :enable_automerge => :environment do
    enable_automerge
  end

  namespace :satellites do
    desc "GITLAB | Create satellite repos"
    task create: 'gitlab:enable_automerge'
  end


  # Task methods
  ##########################

  def enable_automerge
    warn_user_is_not_gitlab

    puts "This will update the repository permissions in Gitolite and"
    puts "(re-)create satellite repos for your projects."
    ask_to_continue
    puts ""

    satelite_base_path = Rails.root.join("tmp", "repo_satellites").to_s
    if File.exists?(satelite_base_path)
      puts "#{satelite_base_path.yellow} conaining satellite repos exists already."
      answer = prompt("#{"Do you want to remove it and recreate ".blue}#{"all".blue.underline}#{" satellites (y/n)? ".blue}", %w{y n})
      if answer == "y"
        print "Removing #{satelite_base_path.yellow} ... "
        Kernel.system("rm -rf #{satelite_base_path}")
        puts "done".green
      end
      puts ""
    end

    puts "Updating repo permissions ..."
    Gitlab::Gitolite.new.enable_automerge
    puts "... #{"done".green}"
    puts ""

    print "Creating satellites for ..."
    unless Project.count > 0
      puts "skipping, because you have no projects".magenta
      return
    end
    puts ""

    Project.find_each(batch_size: 100) do |project|
      print "#{project.name_with_namespace.yellow} ... "

      unless project.repo_exists?
        puts "skipping, because the repo is empty".magenta
        next
      end

      if project.satellite.exists?
        puts "exists already".green
      else
        puts ""
        project.satellite.create

        print "... "
        if $?.success?
          puts "created".green
        else
          puts "error".red
        end
      end
    end
  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".red
    exit 1
  end
end
