# frozen_string_literal: true

require 'gitlab-test-balancing'

require 'webmock/rspec'

RSpec.configure do |config|
  # The client uses WebMock's saved original Net::HTTP in production so its own
  # API calls bypass stubbing. In specs we want WebMock to intercept those calls,
  # so force the plain Net::HTTP class.
  config.before do
    allow_any_instance_of(Gitlab::TestBalancing::Client) # rubocop:disable RSpec/AnyInstanceOf -- simplest way to route the client through WebMock in specs
      .to receive(:net_http_class).and_return(Net::HTTP)
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
