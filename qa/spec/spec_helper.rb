# frozen_string_literal: true

require_relative '../qa'

require 'securerandom'
require 'pathname'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'

require_relative 'qa_deprecation_toolkit_env'
QaDeprecationToolkitEnv.configure!

Knapsack::Adapters::RSpecAdapter.bind if QA::Runtime::Env.knapsack?

QA::Runtime::Browser.configure! unless QA::Runtime::Env.dry_run
QA::Runtime::AllureReport.configure!
QA::Runtime::Scenario.from_env(QA::Runtime::Env.runtime_scenario_attributes)

Dir[::File.join(__dir__, "support/shared_examples/*.rb")].sort.each { |f| require f }
Dir[::File.join(__dir__, "support/shared_contexts/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.include QA::Support::Matchers::EventuallyMatcher
  config.include QA::Support::Matchers::HaveMatcher

  config.add_formatter QA::Support::Formatters::ContextFormatter
  config.add_formatter QA::Support::Formatters::QuarantineFormatter
  config.add_formatter QA::Support::Formatters::TestStatsFormatter if QA::Runtime::Env.export_metrics?

  config.prepend_before do |example|
    QA::Runtime::Logger.debug("\nStarting test: #{example.full_description}\n")

    # Reset fabrication counters tracked in resource base
    Thread.current[:api_fabrication] = 0
    Thread.current[:browser_ui_fabrication] = 0
  end

  config.after do
    # If a .netrc file was created during the test, delete it so that subsequent tests don't try to use the same logins
    QA::Git::Repository.new.delete_netrc
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
    # If any tests failed, leave the resources behind to help troubleshoot
    QA::Resource::ReusableProject.remove_all_via_api! unless suite.reporter.failed_examples.present?

    # Write all test created resources to JSON file
    QA::Tools::TestResourceDataProcessor.write_to_file
  end

  config.append_after(:suite) do
    QA::Tools::KnapsackReport.move_regenerated_report if QA::Runtime::Env.knapsack?
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

  if ENV['CI'] && !QA::Runtime::Env.disable_rspec_retry?
    non_quarantine_retries = QA::Runtime::Env.ci_project_name =~ /staging|canary|production/ ? 3 : 2
    config.around do |example|
      retry_times = example.metadata.key?(:quarantine) ? 1 : non_quarantine_retries
      example.run_with_retry retry: retry_times
    end
  end
end
