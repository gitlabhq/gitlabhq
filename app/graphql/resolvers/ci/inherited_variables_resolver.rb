# frozen_string_literal: true

module Resolvers
  module Ci
    class InheritedVariablesResolver < BaseResolver
      type Types::Ci::ProjectVariableType.connection_type, null: true

      def resolve
        ::Ci::GroupVariable.for_groups(object.group&.self_and_ancestor_ids) || []
      end
    end
  end
end
