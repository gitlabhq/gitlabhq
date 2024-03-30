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
          describe_run(*args, passed: true, &describe_body)
        end

        def describe_unsuccessfully(*args, &describe_body)
          describe_run(*args, passed: false, &describe_body)
        end

        def send_stop_notification
          reporter.notify(
            :stop,
            ::RSpec::Core::Notifications::ExamplesNotification.new(reporter)
          )
        end

        def reporter
          ::RSpec.configuration.reporter
        end

        private

        def describe_run(*args, passed: true, &describe_body)
          example_group = ::RSpec.describe(*args, &describe_body)
          ran_successfully = example_group.run reporter
          expect(ran_successfully).to eq passed
          example_group
        end
      end
    end
  end
end
