desc "GITLAB | Build internal ids for issues and merge requests"
task migrate_iids: :environment do
  puts 'Issues'.yellow
  sql = "UPDATE issues SET iid = id WHERE iid IS NULL;"
  ActiveRecord::Base.connection.execute(sql)

  puts 'done'
  puts 'Merge Requests'.yellow
  sql = "UPDATE merge_requests SET iid = id WHERE iid IS NULL;"
  ActiveRecord::Base.connection.execute(sql)

  puts 'done'
  puts 'Milestones'.yellow
  sql = "UPDATE milestones SET iid = id WHERE iid IS NULL;"
  ActiveRecord::Base.connection.execute(sql)

  puts 'done'
end
