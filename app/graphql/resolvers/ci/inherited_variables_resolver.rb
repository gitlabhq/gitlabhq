# frozen_string_literal: true

module Resolvers
  module Ci
    class InheritedVariablesResolver < BaseResolver
      type Types::Ci::ProjectVariableType.connection_type, null: true

      argument :sort, Types::Ci::GroupVariablesSortEnum,
        required: false, default_value: :created_desc,
        description: 'Sort variables by the criteria.'

      def resolve(sort:)
        ::Ci::GroupVariablesFinder.new(object, sort).execute
      end
    end
  end
end
