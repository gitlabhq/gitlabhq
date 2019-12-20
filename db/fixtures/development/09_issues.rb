require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  Rake::Task["gitlab:seed:issues"].invoke
end
