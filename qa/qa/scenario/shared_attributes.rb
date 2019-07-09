# frozen_string_literal: true

module QA
  module Scenario
    module SharedAttributes
      include Bootable

      attribute :gitlab_address, '--address URL', 'Address of the instance to test'
      attribute :enable_feature, '--enable-feature FEATURE_FLAG', 'Enable a feature before running tests'
      attribute :parallel, '--parallel', 'Execute tests in parallel'
    end
  end
end
