# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class ContextFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Specs::Helpers::ContextSelector

        ::RSpec::Core::Formatters.register(
          self,
          :example_group_started,
          :example_started
        )

        # Starts example group
        # @param [RSpec::Core::Notifications::GroupNotification] example_group_notification
        # @return [void]
        def example_group_started(example_group_notification)
          set_skip_metadata(example_group_notification.group)
        end

        # Starts example
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_started(example_notification)
          example = example_notification.example

          # if skip propagated from example_group, do not reset skip metadata
          set_skip_metadata(example_notification.example) unless example.metadata[:skip]
        end

        private

        # Skip example_group or example
        #
        # @param [<RSpec::Core::ExampleGroup, RSpec::Core::Example>] example
        # @return [void]
        def set_skip_metadata(example)
          return if Runtime::Scenario.attributes[:test_metadata_only]
          return skip_only(example.metadata) if example.metadata.key?(:only)
          return skip_except(example.metadata) if example.metadata.key?(:except)
        end

        # Skip based on 'only' condition
        #
        # @param [Hash] metadata
        # @return [void]
        def skip_only(metadata)
          return if context_matches?(metadata[:only])

          metadata[:skip] = 'Test is not compatible with this environment or pipeline'
        end

        # Skip based on 'except' condition
        #
        # @param [Hash] metadata
        # @return [void]
        def skip_except(metadata)
          return unless except?(metadata[:except])

          metadata[:skip] = 'Test is excluded in this job'
        end
      end
    end
  end
end
