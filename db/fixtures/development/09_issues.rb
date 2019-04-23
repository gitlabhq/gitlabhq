require './spec/support/sidekiq'

Gitlab::Seeder.quiet do
  Rake::Task["gitlab:seed:issues"].invoke
end
