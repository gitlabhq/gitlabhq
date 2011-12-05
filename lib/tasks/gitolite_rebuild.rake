desc "Rebuild each project at gitolite config"
task :gitolite_rebuild => :environment  do
  puts "Starting Projects"
  Project.find_each(:batch_size => 100) do |project|
    puts
    puts "=== #{project.name}"
    project.update_repository
    puts
  end
  puts "Done with projects"

  puts "Starting Key"
  Key.find_each(:batch_size => 100) do |project|
    project.update_repository
    print '.'
  end
  puts "Done with keys"
end
