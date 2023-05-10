# frozen_string_literal: true

module Resolvers
  module Ci
    class InheritedVariablesResolver < BaseResolver
      type Types::Ci::ProjectVariableType.connection_type, null: true

      def resolve
        object.group&.self_and_ancestors&.flat_map(&:variables) || []
      end
    end
  end
end
