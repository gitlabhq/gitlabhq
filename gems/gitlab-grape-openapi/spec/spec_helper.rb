# frozen_string_literal: true

require "gitlab-grape-openapi"
require "grape"
require "grape-entity"
require "fixtures/user_entity"
require "fixtures/user/person_entity"
require "fixtures/test_audit_events"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
