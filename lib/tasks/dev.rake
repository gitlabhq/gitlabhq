namespace :dev do
  desc "GITLAB | Setup developer environment (db, fixtures)"
  task :setup => :environment do
    ENV['force'] = 'yes'
    Rake::Task["db:setup"].invoke
    Rake::Task["db:seed_fu"].invoke
    Rake::Task["gitlab:shell:setup"].invoke
  end
end

