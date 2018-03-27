task dev: ["dev:setup"]

namespace :dev do
  desc "GitLab | Setup developer environment (db, fixtures)"
  task setup: :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke
    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc "GitLab | Eager load application"
  task load: :environment do
    Rails.application.eager_load!
  end
end
