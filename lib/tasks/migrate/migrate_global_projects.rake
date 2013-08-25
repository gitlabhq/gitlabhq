desc "GITLAB | Migrate Global Projects to Namespaces"
task migrate_global_projects: :environment do
  found = Project.where(namespace_id: nil).count
  if found > 0
    puts "Global namespace is deprecated. We found #{found} projects stored in global namespace".yellow
    puts "You may abort this task and move them to group/user namespaces manually."
    puts "If you want us to move this projects under owner namespaces then continue"
    ask_to_continue
  else
    puts "No global projects found. Proceed with update.".green
  end

  Project.where(namespace_id: nil).find_each(batch_size: 20) do |project|
    begin
      project.transfer(project.owner.namespace)
      print '.'
    rescue => ex
      puts ex.message
      print 'F'
    end
  end
end

