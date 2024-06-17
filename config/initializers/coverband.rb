# frozen_string_literal: true

# Configuration used by coverband gem when "COVERBAND_ENABLED" is set to "true"
return unless Gitlab::Utils.to_boolean(ENV['COVERBAND_ENABLED'], default: false)

require 'coverband'

Coverband.configure do |config|
  config.store = Coverband::Adapters::RedisStore.new(Gitlab::Redis::SharedState.redis)
  config.background_reporting_sleep_seconds = 1
  config.reporting_wiggle = nil # Since this is not run in production disable wiggle and report every second.
  config.ignore += %w[spec/.* lib/tasks/.*
    config/application.rb config/boot.rb config/initializers/.* db/post_migrate/.*
    config/puma.rb bin/.* config/environments/.* db/migrate/.*]

  config.verbose = true
  config.csp_policy = true
  config.logger = Gitlab::AppLogger
end
