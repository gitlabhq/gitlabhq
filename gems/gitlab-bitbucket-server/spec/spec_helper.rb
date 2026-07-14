# frozen_string_literal: true

require 'rspec/mocks'
require 'webmock/rspec'
require 'rspec-parameterized'
require 'json'

WebMock.disable_net_connect!

require 'bitbucket_server'

FIXTURE_PATH = File.expand_path('fixtures', __dir__)

def fixture_file(path)
  File.read(File.join(FIXTURE_PATH, path))
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
