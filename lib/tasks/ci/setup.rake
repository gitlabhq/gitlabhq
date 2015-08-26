namespace :ci do
  desc "GitLab CI | Setup gitlab db"
  task :setup do
    Rake::Task["db:setup"].invoke
    Rake::Task["ci:add_limits_mysql"].invoke
  end
end
