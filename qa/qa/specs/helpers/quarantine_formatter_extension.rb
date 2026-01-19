# frozen_string_literal: true

# This extension is for GitlabQuality::TestTooling::TestQuarantine::QuarantineHelper
# in gitlab_quality-test_tooling gem to cover cases when test metadata has
# tags like `quarantine: { only: { subdomain: :staging } }`

module QA
  module Specs
    module Helpers
      module QuarantineFormatterExtension
        def skip_or_run_quarantined_tests_or_contexts(example)
          quarantine_tag = example.metadata[:quarantine]

          # Check if context matches - if it doesn't, return without skipping
          return if quarantine_tag.is_a?(Hash) &&
            quarantine_tag.key?(:only) &&
            !ContextSelector.context_matches?(quarantine_tag[:only])

          # Call the original gem method for other cases
          super
        end
      end
    end
  end
end

# Prepend the extension to the gem's QuarantineHelper module
GitlabQuality::TestTooling::TestQuarantine::QuarantineHelper.prepend(QA::Specs::Helpers::QuarantineFormatterExtension)
