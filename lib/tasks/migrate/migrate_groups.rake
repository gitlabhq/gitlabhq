desc "GITLAB | Migrate Groups to match v6.0"
task migrate_groups: :environment do
  puts "This will add group owners to group membership"
  ask_to_continue

  Group.find_each(batch_size: 20) do |group|
    begin
      group.send :add_owner
      print '.'
    rescue => ex
      puts ex.message
      print 'F'
    end
  end
end

