module Ci
  class Scheduler
    def perform
      projects = Ci::Project.where(always_build: true).all
      projects.each do |project|
        last_commit = project.commits.last
        next unless last_commit && last_commit.last_build

        interval = project.polling_interval
        if (last_commit.last_build.created_at + interval.hours) < Time.now
          last_commit.retry
        end
      end
    end
  end
end
