# frozen_string_literal: true

Rake::Task["test"].clear

desc "GitLab | Run all tests"
task :test do
  Rake::Task["gitlab:test"].invoke
end
