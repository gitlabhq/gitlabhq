# frozen_string_literal: true

require 'active_support/testing/time_helpers'
require 'factory_bot'

require_relative '../../qa'

QA::Specs::QaDeprecationToolkitEnv.configure!

Knapsack::Adapters::RSpecAdapter.bind if QA::Runtime::Env.knapsack?

# TODO: move all classes that perform rspec configuration under spec/helpers
QA::Support::GitlabAddress.define_gitlab_address_attribute!
QA::Runtime::Browser.configure!
QA::Specs::Helpers::FeatureSetup.configure!
QA::Specs::Helpers::FastQuarantine.configure!
QA::Runtime::AllureReport.configure!
QA::Service::DockerRun::Video.configure!

QA::Runtime::Scenario.from_env(QA::Runtime::Env.runtime_scenario_attributes)

# Enable zero monkey patching mode before loading any other RSpec code.
RSpec.configure(&:disable_monkey_patching!)

# For JH additionally process when `jh/` exists
require_relative('../../../jh/qa/qa/specs/spec_helper') if GitlabEdition.jh?

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include QA::Support::Matchers::EventuallyMatcher
  config.include QA::Support::Matchers::HaveMatcher
  config.include FactoryBot::Syntax::Methods

  FactoryBot.definition_file_paths = %w[qa/factories qa/ee/factories]

  config.add_formatter QA::Support::Formatters::ContextFormatter
  config.add_formatter QA::Support::Formatters::QuarantineFormatter
  config.add_formatter QA::Support::Formatters::FeatureFlagFormatter
  config.add_formatter QA::Support::Formatters::TestMetricsFormatter if QA::Runtime::Env.running_in_ci?
  config.add_formatter QA::Support::Formatters::CoverbandFormatter if QA::Runtime::Env.coverband_enabled?

  config.example_status_persistence_file_path = ENV.fetch('RSPEC_LAST_RUN_RESULTS_FILE', 'tmp/examples.txt')

  config.prepend_before do |example|
    if QA::Runtime::Env.parallel_run?
      QA::Runtime::Logger.info("Starting test - PID #{Process.pid}: #{Rainbow(example.full_description).bright}")
    else
      QA::Runtime::Logger.info("Starting test: #{Rainbow(example.full_description).bright}")
    end

    QA::Runtime::Example.current = example

    visit(QA::Runtime::Scenario.gitlab_address) if QA::Runtime::Env.mobile_layout?

    # Reset fabrication counters tracked in resource base
    Thread.current[:api_fabrication] = 0
    Thread.current[:browser_ui_fabrication] = 0
  end

  config.prepend_before(:suite) do
    # Perform before hooks at the very start of the test run, perform once for parallel runs
    QA::Runtime::Release.perform_before_hooks unless QA::Runtime::Env.dry_run || QA::Runtime::Env.parallel_run?
  end

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.after do
    # If a .netrc file was created during the test, delete it so that subsequent tests don't try to use the same logins
    QA::Git::Repository.new.delete_netrc
  end

  config.prepend_after do |example|
    page = Capybara.page
    QA::Support::PageErrorChecker.log_request_errors(page)

    QA::Support::PageErrorChecker.check_page_for_error_code(page) if example.exception
  end

  # Add fabrication time to spec metadata
  config.append_after do |example|
    example.metadata[:api_fabrication] = Thread.current[:api_fabrication]
    example.metadata[:browser_ui_fabrication] = Thread.current[:browser_ui_fabrication]
  end

  config.after(:context) do
    if !QA::Runtime::Browser.blank_page? && QA::Page::Main::Menu.perform(&:signed_in?)
      QA::Page::Main::Menu.perform(&:sign_out)
      raise(
        <<~ERROR
          The test left the browser signed in.

          Usually, Capybara prevents this from happening but some things can
          interfere. For example, if it has an `after(:context)` block that logs
          in, the browser will stay logged in and this will cause the next test
          to fail.

          Please make sure the test does not leave the browser signed in.
        ERROR
      )
    end
  end

  config.after(:suite) do |suite|
    # Write all test created resources to JSON file
    QA::Tools::TestResourceDataProcessor.write_to_file(suite.reporter.failed_examples.any?)
  end

  config.append_after(:suite) do
    QA::Support::KnapsackReport.move_regenerated_report if QA::Runtime::Env.knapsack?
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.expose_dsl_globally = true
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # This option allows to use shorthand aliases for adding :focus metadata - fit, fdescribe and fcontext
  config.filter_run_when_matching :focus
end

Dir[::File.join(__dir__, "features/shared_examples/**/*.rb")].each { |f| require f }
Dir[::File.join(__dir__, "features/shared_contexts/**/*.rb")].each { |f| require f }
