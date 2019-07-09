# frozen_string_literal: true

require_relative '../qa'
require 'rspec/retry'

if ENV['CI'] && QA::Runtime::Env.knapsack? && !ENV['NO_KNAPSACK']
  require 'knapsack'
  Knapsack::Adapters::RSpecAdapter.bind
end

QA::Runtime::Browser.configure!

QA::Runtime::Scenario.from_env(QA::Runtime::Env.runtime_scenario_attributes) if QA::Runtime::Env.runtime_scenario_attributes

%w[helpers shared_examples].each do |d|
  Dir[::File.join(__dir__, d, '**', '*.rb')].each { |f| require f }
end

RSpec.configure do |config|
  QA::Specs::Helpers::Quarantine.configure_rspec

  config.before do |example|
    QA::Runtime::Logger.debug("Starting test: #{example.full_description}") if QA::Runtime::Env.debug?
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.expose_dsl_globally = true
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # show retry status in spec process
  config.verbose_retry = true

  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  if ENV['CI']
    config.around do |example|
      retry_times = example.metadata.keys.include?(:quarantine) ? 1 : 2
      example.run_with_retry retry: retry_times
    end
  end
end
