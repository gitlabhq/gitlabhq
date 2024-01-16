# frozen_string_literal: true

require 'gitlab/secret_detection'
require 'rspec-parameterized'
require 'rspec-benchmark'
require 'benchmark-malloc'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include RSpec::Benchmark::Matchers

  Dir['./spec/support/**/*.rb'].each { |f| require f }

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # configure benchmark factors
  RSpec::Benchmark.configure do |cfg|
    # to avoid retention of allocated memory by the perf tests in the main process
    cfg.run_in_subprocess = true
  end
end
