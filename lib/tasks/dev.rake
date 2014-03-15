task dev: ["dev:setup"]

namespace :dev do
  desc "GITLAB | Setup developer environment (db, fixtures)"
  task :setup => :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke
    Rake::Task["gitlab:shell:setup"].invoke
  end
end
