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
  end
end
