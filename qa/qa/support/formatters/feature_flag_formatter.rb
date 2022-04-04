# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class FeatureFlagFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Specs::Helpers::FeatureFlag

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

          skip_or_run_feature_flag_tests_or_contexts(group)
        end

        # Starts example
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_started(example_notification)
          example = example_notification.example

          # if skip propagated from example_group, do not reset skip metadata
          skip_or_run_feature_flag_tests_or_contexts(example) unless example.metadata[:skip]
        end
      end
    end
  end
end
