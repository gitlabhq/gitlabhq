namespace :gitlab do
  namespace :gitolite do
    desc "GITLAB | Rebuild each project in Gitolite config"
    task :update_repos => :environment do
      warn_user_is_not_gitlab

      puts "Rebuilding projects ... "
      Project.find_each(:batch_size => 100) do |project|
        puts "#{project.name_with_namespace.yellow} ... "
        project.update_repository
        puts "... #{"done".green}"
      end
    end

    desc "GITLAB | Rebuild each user key in Gitolite config"
    task :update_keys => :environment  do
      warn_user_is_not_gitlab

      puts "Rebuilding keys ... "
      Key.find_each(:batch_size => 100) do |key|
        puts "#{key.identifier.yellow} ... "
        Gitlab::Gitolite.new.set_key(key.identifier, key.key, key.projects)
        puts "... #{"done".green}"
      end
    end
  end
end
