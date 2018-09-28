Rake::Task["test"].clear

desc "GitLab | Run all tests"
task :test do
  Rake::Task["gitlab:test"].invoke
end
