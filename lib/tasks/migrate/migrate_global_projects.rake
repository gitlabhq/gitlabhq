desc "GITLAB | Migrate Global Projects to Namespaces"
task migrate_global_projects: :environment do
  puts "This will move all projects without namespace to owner namespace"
  ask_to_continue

  Project.where(namespace_id: nil).find_each(batch_size: 20) do |project|

    # TODO: transfer code here
    print '.'
  end
end

