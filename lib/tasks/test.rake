Rake::Task["test"].clear

desc "GITLAB | Run all tests"
task :test do
  Rake::Task["gitlab:test"].invoke
end

unless Rails.env.production?
  require 'coveralls/rake/task'
  Coveralls::RakeTask.new
  desc "GITLAB | Run all tests on CI with simplecov"
  task :test_ci => [:spinach, :spec, 'coveralls:push']
end
