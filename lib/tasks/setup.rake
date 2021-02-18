# frozen_string_literal: true

desc "GitLab | Setup gitlab db"
task :setup do
  Rake::Task["gitlab:setup"].invoke
end
