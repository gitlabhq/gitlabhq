namespace :gitlab do
  namespace :gitolite do
    desc "GITLAB | Rebuild each user key in Gitolite config"
    task :update_keys => :environment  do
      update_keys
    end

    desc "GITLAB | Rebuild each project in Gitolite config"
    task :update_repos => :environment do
      update_repos
    end


    # Task methods
    ########################

    def update_keys
      warn_user_is_not_gitlab

      puts "This will rebuild and replace the user SSH keys configuration in Gitolite."
      ask_to_continue
      puts ""

      puts "Rebuilding keys ... "
      Key.find_each(:batch_size => 100) do |key|
        puts "#{key.identifier.yellow} ... "
        Gitlab::Gitolite.new.set_key(key.identifier, key.key, key.projects)
        puts "... #{"done".green}"
      end
    rescue Gitlab::TaskAbortedByUserError
      puts "Quitting...".red
      exit 1
    end

    def update_repos
      warn_user_is_not_gitlab

      puts "This will rebuild and relpace the projects configuration in Gitolite."
      ask_to_continue
      puts ""

      puts "Rebuilding projects ... "
      Project.find_each(:batch_size => 100) do |project|
        puts "#{project.name_with_namespace.yellow} ... "
        project.update_repository
        puts "... #{"done".green}"
      end
    rescue Gitlab::TaskAbortedByUserError
      puts "Quitting...".red
      exit 1
    end
  end
end
