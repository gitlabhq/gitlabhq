# frozen_string_literal: true

require_relative '../../qa'
require 'active_support/testing/time_helpers'

QA::Specs::QaDeprecationToolkitEnv.configure!

Knapsack::Adapters::RSpecAdapter.bind if QA::Runtime::Env.knapsack?

QA::Support::GitlabAddress.define_gitlab_address_attribute!
QA::Runtime::Browser.configure! unless QA::Runtime::Env.dry_run
QA::Runtime::AllureReport.configure!
QA::Runtime::Scenario.from_env(QA::Runtime::Env.runtime_scenario_attributes)
QA::Support::KnapsackReport.configure!

# Enable zero monkey patching mode before loading any other RSpec code.
RSpec.configure(&:disable_monkey_patching!)

# For JH additionally process when `jh/` exists
require_relative('../../../jh/qa/qa/specs/spec_helper') if GitlabEdition.jh?

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include QA::Support::Matchers::EventuallyMatcher
  config.include QA::Support::Matchers::HaveMatcher

  config.add_formatter QA::Support::Formatters::ContextFormatter
  config.add_formatter QA::Support::Formatters::QuarantineFormatter
  config.add_formatter QA::Support::Formatters::FeatureFlagFormatter
  config.add_formatter QA::Support::Formatters::TestMetricsFormatter if QA::Runtime::Env.running_in_ci?

  config.prepend_before do |example|
    QA::Runtime::Logger.info("Starting test: #{Rainbow(example.full_description).bright}")
    QA::Runtime::Example.current = example

    visit(QA::Runtime::Scenario.gitlab_address) if QA::Runtime::Env.mobile_layout?

    # Reset fabrication counters tracked in resource base
    Thread.current[:api_fabrication] = 0
    Thread.current[:browser_ui_fabrication] = 0
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

  if ENV['CI'] && !QA::Runtime::Env.disable_rspec_retry?
    # show retry status in spec process
    config.verbose_retry = true

    # show exception that triggers a retry if verbose_retry is set to true
    config.display_try_failure_messages = true

    non_quarantine_retries = QA::Runtime::Env.ci_project_name =~ /staging|canary|production/ ? 3 : 2
    config.around do |example|
      quarantine = example.metadata[:quarantine]
      different_quarantine_context = QA::Specs::Helpers::Quarantine.quarantined_different_context?(quarantine)
      focused_quarantine = QA::Specs::Helpers::Quarantine.filters.key?(:quarantine)

      # Do not disable retry when spec is quarantined but on different environment
      next example.run_with_retry(retry: non_quarantine_retries) if different_quarantine_context && !focused_quarantine

      example.run_with_retry(retry: quarantine ? 1 : non_quarantine_retries)
    end
  end
end

Dir[::File.join(__dir__, "features/shared_examples/**/*.rb")].sort.each { |f| require f }
Dir[::File.join(__dir__, "features/shared_contexts/**/*.rb")].sort.each { |f| require f }
