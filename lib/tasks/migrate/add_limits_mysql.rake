require Rails.root.join('db/migrate/limits_to_mysql')

desc "GitLab | Add limits to strings in mysql database"
task add_limits_mysql: :environment do
  puts "Adding limits to schema.rb for mysql"
  LimitsToMysql.new.up
end
