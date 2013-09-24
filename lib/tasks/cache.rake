namespace :cache do
  desc "GITLAB | Clear redis cache"
  task :clear => :environment do
    Rails.cache.clear
  end
end
