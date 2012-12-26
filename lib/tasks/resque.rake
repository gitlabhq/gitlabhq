require 'resque/tasks'

namespace :resque do
  task setup: :environment do
    Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
  end

  desc "Resque | kill all workers (using -QUIT), god will take care of them"
  task :stop_workers => :environment do
    pids = Array.new

    Resque.workers.each do |worker|
      pids << worker.to_s.split(/:/).second
    end

    if pids.size > 0
      system("kill -QUIT #{pids.join(' ')}")
    end
  end
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"
