# frozen_string_literal: true

require 'rspec/core'

module QA
  module Specs
    module Helpers
      module Quarantine
        include ::RSpec::Core::Pending

        extend self

        def configure_rspec
          ::RSpec.configure do |config|
            config.before(:context, :quarantine) do
              Quarantine.skip_or_run_quarantined_contexts(config.inclusion_filter.rules, self.class)
            end

            config.before do |example|
              Quarantine.skip_or_run_quarantined_tests_or_contexts(config.inclusion_filter.rules, example)
            end
          end
        end

        # Skip the entire context if a context is quarantined. This avoids running
        # before blocks unnecessarily.
        def skip_or_run_quarantined_contexts(filters, example)
          return unless example.metadata.key?(:quarantine)

          skip_or_run_quarantined_tests_or_contexts(filters, example)
        end

        # Skip tests in quarantine unless we explicitly focus on them.
        def skip_or_run_quarantined_tests_or_contexts(filters, example)
          if filters.key?(:quarantine)
            included_filters = filters_other_than_quarantine(filters)

            # If :quarantine is focused, skip the test/context unless its metadata
            # includes quarantine and any other filters
            # E.g., Suppose a test is tagged :smoke and :quarantine, and another is tagged
            # :ldap and :quarantine. If we wanted to run just quarantined smoke tests
            # using `--tag quarantine --tag smoke`, without this check we'd end up
            # running that ldap test as well because of the :quarantine metadata.
            # We could use an exclusion filter, but this way the test report will list
            # the quarantined tests when they're not run so that we're aware of them
            skip("Only running tests tagged with :quarantine and any of #{included_filters.keys}") if should_skip_when_focused?(example.metadata, included_filters)
          else
            if example.metadata.key?(:quarantine)
              quarantine_tag = example.metadata[:quarantine]

              if quarantine_tag.is_a?(Hash) && quarantine_tag&.key?(:only)
                # If the :quarantine hash contains :only, we respect that.
                # For instance `quarantine: { only: { subdomain: :staging } }` will only quarantine the test when it runs against staging.
                return unless ContextSelector.context_matches?(quarantine_tag[:only])
              end

              skip(quarantine_message(quarantine_tag))
            end
          end
        end

        def filters_other_than_quarantine(filter)
          filter.reject { |key, _| key == :quarantine }
        end

        def quarantine_message(quarantine_tag)
          quarantine_message = %w(In quarantine)
          quarantine_message << case quarantine_tag
                                when String
                                  ": #{quarantine_tag}"
                                when Hash
                                  quarantine_tag.key?(:issue) ? ": #{quarantine_tag[:issue]}" : ''
                                else
                                  ''
                                end

          quarantine_message.join(' ').strip
        end

        # Checks if a test or context should be skipped.
        #
        # Returns true if
        # - the metadata does not includes the :quarantine tag
        # or if
        # - the metadata includes the :quarantine tag
        # - and the filter includes other tags that aren't in the metadata
        def should_skip_when_focused?(metadata, included_filters)
          return true unless metadata.key?(:quarantine)
          return false if included_filters.empty?

          (metadata.keys & included_filters.keys).empty?
        end
      end
    end
  end
end
