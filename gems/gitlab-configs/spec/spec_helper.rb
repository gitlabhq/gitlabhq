# frozen_string_literal: true

require 'active_support/all'
require 'gitlab/configs'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset the global mutation-warning callback after every example so a
  # callback set in one spec cannot leak into another under --order random.
  config.after { Gitlab::Configs.on_mutation_warning = nil }
end
