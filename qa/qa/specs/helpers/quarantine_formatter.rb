# frozen_string_literal: true

require 'rspec/core'
require "rspec/core/formatters/base_formatter"

module QA
  module Specs
    module Helpers
      class QuarantineFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Quarantine

        ::RSpec::Core::Formatters.register(
          self,
          :example_group_started,
          :example_started
        )

        # Starts example group
        # @param [RSpec::Core::Notifications::GroupNotification] example_group_notification
        # @return [void]
        def example_group_started(example_group_notification)
          group = example_group_notification.group

          skip_or_run_quarantined_tests_or_contexts(filters, group)
        end

        # Starts example
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_started(example_notification)
          example = example_notification.example

          # if skip propagated from example_group, do not reset skip metadata
          skip_or_run_quarantined_tests_or_contexts(filters, example) unless example.metadata[:skip]
        end

        private

        def filters
          @filters ||= ::RSpec.configuration.inclusion_filter.rules
        end
      end
    end
  end
end
