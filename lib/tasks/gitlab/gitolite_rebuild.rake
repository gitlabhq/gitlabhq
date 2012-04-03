namespace :gitlab do
  namespace :gitolite do
    desc "GITLAB | Rebuild each project at gitolite config"
    task :update_repos => :environment  do
      puts "Starting Projects"
      Project.find_each(:batch_size => 100) do |project|
        puts
        puts "=== #{project.name}"
        project.update_repository
        puts
      end
      puts "Done with projects"
    end

    desc "GITLAB | Rebuild each key at gitolite config"
    task :update_keys => :environment  do
      puts "Starting Key"
      Key.find_each(:batch_size => 100) do |key|
        key.update_repository
        print '.'
      end
      puts "Done with keys"
    end
  end
end
