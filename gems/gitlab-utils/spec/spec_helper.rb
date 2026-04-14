# frozen_string_literal: true

require 'rails'
require 'rspec/mocks'
require 'rspec-benchmark'
require 'rspec-parameterized'

require 'gitlab/rspec/all'
require 'gitlab/utils/all'

Digest::UUID.use_rfc4122_namespaced_uuids = true if Digest::UUID.respond_to?(:use_rfc4122_namespaced_uuids=)

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
  config.include StubENV
  config.include NextInstanceOf

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
