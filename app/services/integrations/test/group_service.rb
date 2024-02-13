# frozen_string_literal: true

module Integrations
  module Test
    class GroupService < Integrations::Test::BaseService
      include Integrations::GroupTestData
      include Gitlab::Utils::StrongMemoize

      def group
        integration.group
      end
      strong_memoize_attr :group

      private

      def data
        case event || integration.default_test_event
        when 'push', 'tag_push'
          push_events_data
        end
      end
      strong_memoize_attr :data
    end
  end
end
