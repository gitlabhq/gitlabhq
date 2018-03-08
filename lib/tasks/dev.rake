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

  task idtest: :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    i = 0
    begin
      project = Project.first
      user = User.second
      issue = Issue.create!(author: user, title: "Issue #{i}", project: project)
      i += 1
      puts issue.iid
    end while i < 10
  end
end
