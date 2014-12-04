namespace :db do
  desc "Seed is replaced with seed_fu"
  task :seed => :environment do
    raise "Please run db:seed_fu instead of db:seed."
  end
end
