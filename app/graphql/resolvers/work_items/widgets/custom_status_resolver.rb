# frozen_string_literal: true

module Resolvers
  module WorkItems
    module Widgets
      class CustomStatusResolver < BaseResolver
        type ::Types::WorkItems::Widgets::CustomStatusType.connection_type, null: true

        def resolve
          # Implement during https://gitlab.com/gitlab-org/gitlab/-/issues/498393
          [::WorkItems::Widgets::CustomStatus.new(nil), ::WorkItems::Widgets::CustomStatus.new(nil)]
        end
      end
    end
  end
end
