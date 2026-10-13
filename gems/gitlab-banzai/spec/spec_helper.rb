# frozen_string_literal: true

require 'rspec-parameterized'

require 'banzai/all'

require_relative 'support/filter_spec_helper'

RSpec.configure do |config|
  # Matches the monolith (spec/support/rspec.rb). RSpec defaults this to true,
  # which locks a mutex on every `let` read.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/379686
  config.threadsafe = false

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
