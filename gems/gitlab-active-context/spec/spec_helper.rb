# frozen_string_literal: true

if ENV['ACTIVE_CONTEXT_SIMPLECOV'] == '1'
  require 'simplecov'
  SimpleCov.start 'rails'
end

require 'active_context'
require 'active_support/all'
require 'aws-sdk-core'
require 'byebug'
require 'faraday/typhoeus'
require 'elasticsearch'
require 'logger'
require 'opensearch'
require 'redis'

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
