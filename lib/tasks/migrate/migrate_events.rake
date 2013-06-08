#This task will migrate the latest project event into the requisite column in projects
desc "GITLAB | Migrate Project Events"
task migrate_project_events: :environment do

  Project.find_each(batch_size: 20) do |p|
    if p.last_activity_at
      puts p.name_with_namespace.light_blue + ' - already has activity time, skipping'
      next
    end

    unless p.last_activity
      puts p.name_with_namespace.red + ' - no actual activity, skipping'
      next
    end

    p.last_activity_at = p.last_activity.created_at
    p.save
    puts p.name_with_namespace.green + ' - FIXED'
  end

end