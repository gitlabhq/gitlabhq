# frozen_string_literal: true

require "gitlab/mfe"
require "rspec-parameterized"

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.disable_monkey_patching!

  # Reset the injected runtime hooks after every example so configuration set
  # in one spec cannot leak into another under --order random.
  config.after { Gitlab::Mfe.reset_configuration! }
end
