namespace :gitlab do
  desc "GITLAB | Run all tests"
  task :test do
    Rails.env = "test"
    Rake::Task["db:setup"].invoke
    Rake::Task["db:seed_fu"].invoke
    Rake::Task["spinach"].invoke
    Rake::Task["spec"].invoke
    Rake::Task["jasmince:ci"].invoke
  end
end
