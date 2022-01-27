# frozen_string_literal: true

require 'rspec/core'

module QA
  module Specs
    module Helpers
      module Quarantine
        include ::RSpec::Core::Pending

        extend self

        # Skip tests in quarantine unless we explicitly focus on them or quarantine disabled
        def skip_or_run_quarantined_tests_or_contexts(example)
          return if Runtime::Env.quarantine_disabled?

          if filters.key?(:quarantine)
            included_filters = filters_other_than_quarantine

            # If :quarantine is focused, skip the test/context unless its metadata
            # includes quarantine and any other filters
            # E.g., Suppose a test is tagged :smoke and :quarantine, and another is tagged
            # :ldap and :quarantine. If we wanted to run just quarantined smoke tests
            # using `--tag quarantine --tag smoke`, without this check we'd end up
            # running that ldap test as well because of the :quarantine metadata.
            # We could use an exclusion filter, but this way the test report will list
            # the quarantined tests when they're not run so that we're aware of them
            if should_skip_when_focused?(example.metadata, included_filters)
              example.metadata[:skip] = "Only running tests tagged with :quarantine and any of #{included_filters.keys}"
            end
          elsif example.metadata.key?(:quarantine)
            quarantine_tag = example.metadata[:quarantine]

            # If the :quarantine hash contains :only, we respect that.
            # For instance `quarantine: { only: { subdomain: :staging } }`
            # will only quarantine the test when it runs against staging.
            return if quarantined_different_context?(quarantine_tag)

            example.metadata[:skip] = quarantine_message(quarantine_tag)
          end
        end

        def filters_other_than_quarantine
          filters.reject { |key, _| key == :quarantine }
        end

        def quarantine_message(quarantine_tag)
          quarantine_message = %w[In quarantine]
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

        def quarantined_different_context?(quarantine)
          quarantine.is_a?(Hash) && quarantine.key?(:only) && !ContextSelector.context_matches?(quarantine[:only])
        end

        def filters
          @filters ||= ::RSpec.configuration.inclusion_filter.rules
        end
      end
    end
  end
end
