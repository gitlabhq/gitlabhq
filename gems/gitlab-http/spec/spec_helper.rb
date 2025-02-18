# frozen_string_literal: true

ENV["RAILS_ENV"] = 'test' # rubocop: disable RSpec/EnvAssignment -- this was not set when running tests

require 'rspec/mocks'

require 'gitlab/rspec/all'
require 'gitlab/http_v2'
require 'gitlab/http_v2/configuration'
require 'gitlab/stub_requests'

require 'webmock/rspec'

RSpec.configure do |config|
  config.include StubENV
  config.include Gitlab::StubRequests

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Gitlab::HTTP_V2.configure do |config|
  config.allowed_internal_uris = [
    URI::HTTP.build(
      scheme: 'http',
      host: 'localhost',
      port: '80'
    ),
    URI::Generic.build(
      scheme: 'ssh',
      host: 'localhost',
      port: '22'
    )
  ]

  config.log_exception_proc = ->(exception, extra_info) do
    # no-op
  end

  config.silent_mode_log_info_proc = ->(message, http_method) do
    # no-op
  end

  config.log_with_level_proc = ->(log_level, message_params) do
    # no-op
  end
end
