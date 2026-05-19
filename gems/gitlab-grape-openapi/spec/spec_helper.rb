# frozen_string_literal: true

require "gitlab-grape-openapi"
require "grape"
require "grape-entity"
require "fixtures/test_audit_events"
require "fixtures/entities/user_entity"
require "fixtures/entities/user/person_entity"
require "fixtures/apis/users_api"
require "fixtures/apis/nested_api"
require "fixtures/apis/deprecated_api"
require "fixtures/apis/special_tags_api"
require "fixtures/apis/excluded_api"
require "fixtures/apis/hidden_api"
require "fixtures/apis/coerced_params_api"
require "fixtures/validations/limit"
require "fixtures/apis/identical_paths_api"
require "fixtures/apis/success_keyword_api"
require "fixtures/apis/url_unsafe_operationid_api"
require "fixtures/validations/types/comma_separated_to_array"
require "fixtures/validations/types/comma_separated_to_integer_array"
require "fixtures/validations/types/hash_of_integer_values"
require "fixtures/validations/types/some_unknown_coercer"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
