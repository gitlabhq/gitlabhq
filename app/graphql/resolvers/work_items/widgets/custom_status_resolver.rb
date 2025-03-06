# frozen_string_literal: true

module Resolvers
  module WorkItems
    module Widgets
      class CustomStatusResolver < BaseResolver
        type ::Types::WorkItems::Widgets::CustomStatusType.connection_type, null: true

        def resolve
          []
        end
      end
    end
  end
end

Resolvers::WorkItems::Widgets::CustomStatusResolver.prepend_mod
