namespace :gitlab do
  desc "GITLAB | Enable usernames and namespaces for user projects"
  task activate_namespaces: :environment do
    print "\nUsernames for users:".yellow

    User.find_each(batch_size: 500) do |user|
      next if user.namespace

      User.transaction do
        username = user.email.match(/^[^@]*/)[0]
        if user.update_attributes!(username: username)
          print '.'.green
        else
          print 'F'.red
        end
      end
    end

    print "\n\nDirs for groups:".yellow

    Group.find_each(batch_size: 500) do |group|
      if group.ensure_dir_exist
        print '.'.green
      else
        print 'F'.red
      end
    end

    print "\n\nMove projects from groups under groups dirs:".yellow
    git_path = Gitlab.config.git_base_path

    Project.where('namespace_id IS NOT NULL').find_each(batch_size: 500) do |project|
      next unless project.group
      next if project.empty_repo?

      group = project.group

      puts "\n"
      print " * #{project.name}: "

      new_path = File.join(git_path, project.path_with_namespace + '.git')

      if File.exists?(new_path)
        print "ok. already at #{new_path}".cyan
        next
      end

      old_path = File.join(git_path, project.path + '.git')

      unless File.exists?(old_path)
        print "missing. not found at #{old_path}".red
        next
      end

      begin
        Gitlab::ProjectMover.new(project, '', group.path).execute
        print "ok. Moved to #{new_path}".green
      rescue
        print "Failed moving to #{new_path}".red
      end
    end

    print "\n\nRebuild gitolite:".yellow
    gitolite = Gitlab::Gitolite.new
    gitolite.update_repositories(Project.where('namespace_id IS NOT NULL'))
    puts "\n"
  end
end
