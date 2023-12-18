# frozen_string_literal: true

require 'rspec/mocks'
require "gitlab/housekeeper"
require "gitlab/housekeeper/git"
require 'webmock/rspec'
require 'gitlab/rspec/all'

RSpec.configure do |config|
  config.include StubENV
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
