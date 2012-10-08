require 'resque/tasks'

# Fix Exception
# ActiveRecord::StatementInvalid
# Error
# PGError: ERROR: prepared statement "a3" already exists
task "resque:setup" => :environment do
  Resque.after_fork do |job|
    ActiveRecord::Base.establish_connection
  end
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"
