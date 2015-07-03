Rake::Task["test"].clear

desc "GitLab | Run all tests"
task :test do
  Rake::Task["gitlab:test"].invoke
end

unless Rails.env.production?
  require 'coveralls/rake/task'
  Coveralls::RakeTask.new
  desc "GitLab | Run all tests on CI with simplecov"
  task :test_ci => [:rubocop, :brakeman, 'jasmine:ci', :spinach, :spec, 'coveralls:push']
end
