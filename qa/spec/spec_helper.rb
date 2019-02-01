require_relative '../qa'

Dir[::File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.before do |example|
    QA::Runtime::Logger.debug("Starting test: #{example.full_description}") if QA::Runtime::Env.debug?

    # If quarantine is tagged, skip tests that have other metadata unless
    # they're also tagged. This lets us run quarantined tests in a particular
    # category without running tests in other categories.
    # E.g., if a test is tagged 'smoke' and 'quarantine', and another is tagged
    # 'ldap' and 'quarantine', if we wanted to run just quarantined smoke tests
    # using `--tag quarantine --tag smoke`, without this check we'd end up
    # running that ldap test as well.
    if config.inclusion_filter[:quarantine]
      skip("Running tests tagged with all of #{config.inclusion_filter.rules.keys}") unless quarantine_and_optional_other_tag?(example, config)
    end
  end

  config.before(:each, :quarantine) do |example|
    # Skip tests in quarantine unless we explicitly focus on them
    # We could use an exclusion filter, but this way the test report will list
    # the quarantined tests when they're not run so that we're aware of them
    skip('In quarantine') unless config.inclusion_filter[:quarantine]
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

# Checks if a test has the 'quarantine' tag and other tags in the inclusion filter.
#
# Returns true if
# - the example metadata includes the quarantine tag
# - and the metadata and inclusion filter both have any other tag
# - or no other tags are in the inclusion filter
def quarantine_and_optional_other_tag?(example, config)
  return false unless example.metadata.keys.include? :quarantine

  filters_other_than_quarantine = config.inclusion_filter.rules.keys.reject { |key| key == :quarantine }

  return true if filters_other_than_quarantine.empty?

  filters_other_than_quarantine.any? { |key| example.metadata.keys.include? key }
end
