# frozen_string_literal: true

require 'rspec/core'

module QA
  module Specs
    module Helpers
      module RSpec
        # We need a reporter for internal tests that's different from the reporter for
        # external tests otherwise the results will be mixed up. We don't care about
        # most reporting, but we do want to know if a test fails
        class RaiseOnFailuresReporter < ::RSpec::Core::NullReporter
          def self.example_failed(example)
            raise example.exception
          end
        end

        # We use an example group wrapper to prevent the state of internal tests
        # expanding into the global state
        # See: https://github.com/rspec/rspec-core/issues/2603
        def describe_successfully(*args, &describe_body)
          example_group = RSpec.describe(*args, &describe_body)
          ran_successfully = example_group.run RaiseOnFailuresReporter
          expect(ran_successfully).to eq true
          example_group
        end
      end
    end
  end
end
