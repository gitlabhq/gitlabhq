# frozen_string_literal: true

require "simplecov"
require "rspec"
require "climate_control"
require "gitlab/cng/cli"

require_relative "command_helper"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
