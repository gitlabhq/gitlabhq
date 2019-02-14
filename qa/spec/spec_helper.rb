require_relative '../qa'

%w[helpers shared_examples].each do |d|
  Dir[::File.join(__dir__, d, '**', '*.rb')].each { |f| require f }
end

RSpec.configure do |config|
  ServerNotRespondingError = Class.new(RuntimeError)

  # The login page could take some time to load the first time it is visited.
  # We visit the login page and wait for it to properly load only once at the beginning of the suite.
  config.before(:suite) do
    if QA::Runtime::Scenario.respond_to?(:gitlab_address)
      QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)

      unless QA::Page::Main::Login.perform(&:page_loaded?)
        raise ServerNotRespondingError, "Login page did not load at #{QA::Page::Main::Login.perform(&:current_url)}"
      end
    end
  end

  config.before(:context) do
    if self.class.metadata.keys.include?(:quarantine)
      skip_or_run_quarantined_tests(self.class.metadata.keys, config.inclusion_filter.rules.keys)
    end
  end

  config.before do |example|
    QA::Runtime::Logger.debug("Starting test: #{example.full_description}") if QA::Runtime::Env.debug?

    skip_or_run_quarantined_tests(example.metadata.keys, config.inclusion_filter.rules.keys)
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
end

# Skip tests in quarantine unless we explicitly focus on them.
# Skip the entire context if a context is tagged. This avoids running before
# blocks unnecessarily.
# If quarantine is focussed, skip tests/contexts that have other metadata
# unless they're also focussed. This lets us run quarantined tests in a
# particular category without running tests in other categories.
# E.g., if a test is tagged 'smoke' and 'quarantine', and another is tagged
# 'ldap' and 'quarantine', if we wanted to run just quarantined smoke tests
# using `--tag quarantine --tag smoke`, without this check we'd end up
# running that ldap test as well.
# We could use an exclusion filter, but this way the test report will list
# the quarantined tests when they're not run so that we're aware of them
def skip_or_run_quarantined_tests(metadata_keys, filter_keys)
  included_filters = filters_other_than_quarantine(filter_keys)

  if filter_keys.include?(:quarantine)
    skip("Only running tests tagged with :quarantine and any of #{included_filters}") unless quarantine_and_optional_other_tag?(metadata_keys, included_filters)
  else
    skip('In quarantine') if metadata_keys.include?(:quarantine)
  end
end

def filters_other_than_quarantine(filter_keys)
  filter_keys.reject { |key| key == :quarantine }
end

# Checks if a test has the 'quarantine' tag and other tags in the inclusion filter.
#
# Returns true if
# - the metadata includes the quarantine tag
#   - and the metadata and inclusion filter both have any other tag
#   - or no other tags are in the inclusion filter
def quarantine_and_optional_other_tag?(metadata_keys, included_filters)
  return false unless metadata_keys.include? :quarantine
  return true if included_filters.empty?

  included_filters.any? { |key| metadata_keys.include? key }
end
