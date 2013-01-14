namespace :gitlab do
  desc "GITLAB | Enable usernames and namespaces for user projects"
  task enable_namespaces: :environment do
    warn_user_is_not_gitlab

    migrate_user_namespaces
    migrate_groups
    migrate_projects

    puts "Rebuild Gitolite ... "
    gitolite = Gitlab::Gitolite.new
    gitolite.update_repositories(Project.where('namespace_id IS NOT NULL'))
    puts "... #{"done".green}"
  end

  def migrate_user_namespaces
    puts "\nGenerate usernames for users without one: ".blue
    User.find_each(batch_size: 500) do |user|
      if user.namespace
        print '-'.cyan
        next
      end

      username = if user.username.present?
                   # if user already has username filled
                   user.username
                 else
                   build_username(user)
                 end

      begin
        User.transaction do
          user.update_attributes!(username: username)
          print '.'.green
        end
      rescue
        print 'F'.red
      end
    end
    puts "\nDone"
  end

  def build_username(user)
    username = nil

    # generate username
    username = user.email.match(/^[^@]*/)[0]
    username.gsub!("+", ".")

    # return username if no mathes
    return username unless User.find_by_username(username)

    # look for same username
    (1..10).each do |i|
      suffixed_username = "#{username}#{i}"

      return suffixed_username unless User.find_by_username(suffixed_username)
    end
  end

  def migrate_groups
    puts "\nCreate directories for groups: ".blue

    Group.find_each(batch_size: 500) do |group|
      begin
        if group.dir_exists?
          print '-'.cyan
        else
          if group.ensure_dir_exist
            print '.'.green
          else
            print 'F'.red
          end
        end
      rescue
        print 'F'.red
      end
    end
    puts "\nDone"
  end

  def migrate_projects
    git_path = Gitlab.config.gitolite.repos_path
    puts "\nMove projects in groups into respective directories ... ".blue
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

    puts "\nDone"
  end
end
