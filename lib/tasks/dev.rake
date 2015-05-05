task dev: ["dev:setup"]

namespace :dev do
  desc "GITLAB | Setup developer environment (db, fixtures)"
  task :setup => :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke
    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc 'GITLAB | Start/restart foreman and watch for changes'
  task :foreman => :environment do
    sh 'rerun --dir app,config,lib -- foreman start'
  end
end
