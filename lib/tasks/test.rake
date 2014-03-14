Rake::Task["test"].clear

desc "GITLAB | Run all tests"
task :test do
  Rake::Task["gitlab:test"].invoke
end

