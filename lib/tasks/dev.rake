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
    project = Project.where(name: 'lkjlkjlkjlkj').first
    user = User.second
    i = 0
    begin
      Issue.create(author: user, title: "Issue #{i}", project: project)
      i += 1
      puts i
    end while true
  end
end
