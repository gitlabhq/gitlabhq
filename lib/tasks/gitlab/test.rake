namespace :gitlab do
  desc "GITLAB | Run both cucumber & rspec"
  task :test => ['cucumber', 'spec']
end

