# frozen_string_literal: true

# This file is loaded from 'initializers/coverband.rb' if coverband is enabled

Coverband.configure do |config|
  config.store = Coverband::Adapters::RedisStore.new(Gitlab::Redis::SharedState.redis)
  config.background_reporting_sleep_seconds = 1
  config.reporting_wiggle = 0 # Since this is not run in production disable wiggle and report every second.
  config.ignore += %w[spec/.* lib/tasks/.*
    config/application.rb config/boot.rb config/initializers/.* db/post_migrate/.*
    config/puma.rb bin/.* config/environments/.* db/migrate/.* ee/app/workers/search/zoekt/.*]

  config.verbose = false # this spams logfile a lot, set to true for debugging locally
  config.logger = Gitlab::AppLogger.primary_logger
end
