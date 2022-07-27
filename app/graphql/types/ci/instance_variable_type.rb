# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class InstanceVariableType < BaseObject
      graphql_name 'CiInstanceVariable'
      description 'CI/CD variables for a GitLab instance.'

      implements(VariableInterface)

      field :environment_scope, GraphQL::Types::String, null: true,
            deprecated: {
              reason: 'No longer used, only available for GroupVariableType and ProjectVariableType',
              milestone: '15.3'
            },
            description: 'Scope defining the environments that can use the variable.'

      def environment_scope
        nil
      end
    end
  end
end
