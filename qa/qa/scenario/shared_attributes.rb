# frozen_string_literal: true

module QA
  module Scenario
    module SharedAttributes
      include Bootable

      attribute :gitlab_address, '--address URL', 'Address of the instance to test'
      attribute :enable_feature, '--enable-feature FEATURE_FLAG', 'Enable a feature before running tests'
      attribute :disable_feature, '--disable-feature FEATURE_FLAG', 'Disable a feature before running tests'
      attribute :set_feature_flags, '--set-feature-flags FEATURE_FLAGS',
        'Set one or more feature flags before running tests. ' \
        'Specify FEATURE_FLAGS as comma-separated flag=state pairs, e.g., "flag1=enabled,flag2=disabled"'
      attribute :parallel, '--parallel', 'Execute tests in parallel'
      attribute :loop, '--loop', 'Execute test repeatedly'
      attribute :count_examples_only, '--count-examples-only', 'Return the number of examples without running them'
      attribute :test_metadata_only, '--test-metadata-only', 'Return all e2e test metadata without running them'
    end
  end
end
