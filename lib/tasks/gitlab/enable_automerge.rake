namespace :gitlab do
  desc "GITLAB | Enable auto merge"
  task :enable_automerge => :environment do
    warn_user_is_not_gitlab

    puts "Updating repo permissions ..."
    Gitlab::Gitolite.new.enable_automerge
    puts "... #{"done".green}"
    puts ""

    print "Creating satellites for ..."
    unless Project.count > 0
      puts "skipping, because you have no projects".magenta
      next
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
  end

  namespace :satellites do
    desc "GITLAB | Create satellite repos"
    task create: 'gitlab:enable_automerge'
  end
end
