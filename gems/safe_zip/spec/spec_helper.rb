# frozen_string_literal: true

require "safe_zip"
require "rspec-parameterized"

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
