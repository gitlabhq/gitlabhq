task dev: ["dev:setup"]

namespace :dev do
  desc "GitLab | Setup developer environment (db, fixtures)"
  task setup: :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke

    # Make sure DB statistics are up to date.
    ActiveRecord::Base.connection.execute('ANALYZE')

    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc "GitLab | Eager load application"
  task load: :environment do
    Rails.configuration.eager_load = true
    Rails.application.eager_load!
  end
end
