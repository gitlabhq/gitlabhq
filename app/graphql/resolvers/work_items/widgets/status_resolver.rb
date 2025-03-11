# frozen_string_literal: true

module Resolvers
  module WorkItems
    module Widgets
      class StatusResolver < BaseResolver
        type ::Types::WorkItems::Widgets::StatusType.connection_type, null: true

        def resolve
          []
        end
      end
    end
  end
end

Resolvers::WorkItems::Widgets::StatusResolver.prepend_mod
