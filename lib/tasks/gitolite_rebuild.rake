desc "Rebuild each project at gitolite config"
task :gitolite_rebuild => :environment  do
  puts "Starting..."
  Project.find_each(:batch_size => 100) do |project|
    puts
    puts "=== #{project.name}"
    project.update_repository
    puts
  end
  puts "Done"
end
