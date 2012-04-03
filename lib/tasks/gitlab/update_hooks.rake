namespace :gitlab do
  namespace :gitolite do
    desc "GITLAB | Rewrite hooks for repos"
    task :update_hooks => :environment  do
      puts "Starting Projects"
      Project.find_each(:batch_size => 100) do |project|
        begin 
          if project.commit
            project.write_hooks 
            print ".".green
          end
        rescue Exception => e
          print e.message.red
        end
      end
      puts "\nDone with projects"
    end
  end
end
