namespace :gitlab do
  namespace :shell do
    desc "GITLAB | Setup gitlab-shell"
    task setup: :environment do
      setup
    end

    desc "GITLAB | Build missing projects"
    task build_missing_projects: :environment do
      Project.find_each(batch_size: 1000) do |project|
        path_to_repo = File.join(Gitlab.config.gitlab_shell.repos_path, "#{project.path_with_namespace}.git")
        if File.exists?(path_to_repo)
          print '-'
        else
          if Gitlab::Shell.new.add_repository(project.path_with_namespace)
            print '.'
          else
            print 'F'
          end
        end
      end
    end
  end

  def setup
    warn_user_is_not_gitlab

    unless ENV['force'] == 'yes'
      puts "This will rebuild an authorized_keys file."
      puts "You will lose any data stored in authorized_keys file."
      ask_to_continue
      puts ""
    end

    Gitlab::Shell.new.remove_all_keys

    Key.find_each(batch_size: 1000) do |key|
      if Gitlab::Shell.new.add_key(key.shell_id, key.key)
        print '.'
      else
        print 'F'
      end
    end

  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".red
    exit 1
  end
end

