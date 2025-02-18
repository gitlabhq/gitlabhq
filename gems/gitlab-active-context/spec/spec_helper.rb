# frozen_string_literal: true

require 'active_context'
require 'active_support/all'
require 'logger'
require 'elasticsearch'
require 'opensearch'
require 'aws-sdk-core'
require 'redis'
require 'byebug'

Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
