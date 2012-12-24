namespace :gitlab do
  namespace :gitolite do
    desc "GITLAB | Rebuild each project at gitolite config"
    task :update_repos => :environment do
      puts "Starting Projects"
      Project.find_each(:batch_size => 100) do |project|
        puts "\n=== #{project.name}"
        project.update_repository
        puts
      end
      puts "Done with projects"
    end

    desc "GITLAB | Rebuild each key at gitolite config"
    task :update_keys => :environment  do
      puts "Starting Key"
      Key.find_each(:batch_size => 100) do |key|
        Gitlab::Gitolite.new.set_key(key.identifier, key.key, key.projects)
        print '.'
      end
      puts "Done with keys"
    end

    desc "GITLAB | Cleanup gitolite config"
    task :cleanup => :environment  do
      warn_user_is_not_gitlab

      real_repos = Project.all.map(&:path_with_namespace)
      real_repos << "gitolite-admin"
      real_repos << "@all"

      remove_flag = ENV['REMOVE']

      puts "Looking for repositories to remove... "
      Gitlab::GitoliteConfig.new.apply do |config|
        all_repos = []
        garbage_repos = []

        all_repos = config.conf.repos.keys
        garbage_repos = all_repos - real_repos

        garbage_repos.each do |repo_name|
          if remove_flag
            config.conf.rm_repo(repo_name)
            print "to remove...".red
          end

          puts repo_name.red
        end
      end

      unless remove_flag
        puts "To cleanup repositories run this command with REMOVE=true".yellow
      end
    end
  end
end
