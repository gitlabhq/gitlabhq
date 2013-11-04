namespace :gitlab do
  desc "GITLAB | Run both spinach and rspec"
  task test: ['db:setup', 'spinach', 'spec']
end
