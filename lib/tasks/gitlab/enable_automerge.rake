namespace :gitlab do
  namespace :satellites do
    desc "GITLAB | Create satellite repos"
    task create: :environment do
      create_satellites
    end
  end

  def create_satellites
    warn_user_is_not_gitlab

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
        print "\n... "
        if project.satellite.create
          puts "created".green
        else
          puts "error".red
        end
      end
    end
  end
end
