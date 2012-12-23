namespace :gitlab do
  desc "GITLAB | Enable usernames and namespaces for user projects"
  task enable_namespaces: :environment do
    warn_user_is_not_gitlab

    print "Generate usernames for users without one: "

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

    puts ""
    print "Create directories for groups: "

    Group.find_each(batch_size: 500) do |group|
      if group.ensure_dir_exist
        print '.'.green
      else
        print 'F'.red
      end
    end
    puts ""

    git_path = Gitlab.config.gitolite.repos_path
    puts ""
    puts "Move projects in groups into respective directories ... "
    Project.where('namespace_id IS NOT NULL').find_each(batch_size: 500) do |project|
      next unless project.group

      group = project.group

      print "#{project.name_with_namespace.yellow} ... "

      new_path = File.join(git_path, project.path_with_namespace + '.git')

      if File.exists?(new_path)
        puts "already at #{new_path}".green
        next
      end

      old_path = File.join(git_path, project.path + '.git')

      unless File.exists?(old_path)
        puts "couldn't find it at #{old_path}".red
        next
      end

      begin
        Gitlab::ProjectMover.new(project, '', group.path).execute
        puts "moved to #{new_path}".green
      rescue
        puts "failed moving to #{new_path}".red
      end
    end

    puts ""
    puts "Rebuild Gitolite ... "
    gitolite = Gitlab::Gitolite.new
    gitolite.update_repositories(Project.where('namespace_id IS NOT NULL'))
    puts "... #{"done".green}"
  end
end
