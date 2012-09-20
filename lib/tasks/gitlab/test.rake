namespace :gitlab do
  desc "GITLAB | Run both spinach and rspec"
  task :test => ['spinach', 'spec']
end
