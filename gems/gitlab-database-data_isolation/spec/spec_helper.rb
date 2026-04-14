# frozen_string_literal: true

require "gitlab-database-data_isolation"
require "rspec-parameterized"
require "gitlab/database/data_isolation/strategies/arel"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

  config.before do
    Gitlab::Database::DataIsolation.reset_configuration!
    Gitlab::Database::DataIsolation::Context.enable!

    Gitlab::Database::DataIsolation.configure do |c|
      c.sharding_key_map = SHARDING_KEY_MAP
    end
  end
end
