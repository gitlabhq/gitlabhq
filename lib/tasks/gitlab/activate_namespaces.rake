namespace :gitlab do
  desc "GITLAB | Enable usernames and namespaces for user projects"
  task activate_namespaces: :environment do
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

    Group.find_each(batch_size: 500) do |group|
      if group.ensure_dir_exist
        print '.'.green
      else
        print 'F'.red
      end
    end

    git_path = Gitlab.config.git_base_path

    Project.where('namespace_id IS NOT NULL').find_each(batch_size: 500) do |project|
      next unless project.group

      group = project.group

      next if File.exists?(File.join(git_path, project.path_with_namespace))

      next unless File.exists?(File.join(git_path, project.path))

      begin
        Gitlab::ProjectMover.new(project, '', group.path).execute
        print '.'.green
      rescue
        print 'F'.red
      end
    end
  end
end
