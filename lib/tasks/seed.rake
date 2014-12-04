namespace :db do
  namespace :seed  do
    desc "Seed is replaced with seed_fu"
    task :dump => :environment do
      raise "Please run db:seed_fu instead of db:seed."
    end
  end
end
