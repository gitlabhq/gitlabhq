Rake::Task["test"].clear

desc "GitLab | Run all tests"
task :test do
  Rake::Task["gitlab:test"].invoke
end

unless Rails.env.production?
  desc "GitLab | Run all tests on CI with simplecov"
  task test_ci: [:rubocop, :brakeman, :teaspoon, :spinach, :spec]
end
