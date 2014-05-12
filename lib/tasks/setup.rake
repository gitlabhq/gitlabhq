desc "GITLAB | Setup gitlab db"
task :setup do
  Rake::Task["gitlab:setup"].invoke
end
