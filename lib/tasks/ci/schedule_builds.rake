namespace :ci do
  desc "GitLab CI | Clean running builds"
  task schedule_builds: :environment do
    Ci::Scheduler.new.perform
  end
end
