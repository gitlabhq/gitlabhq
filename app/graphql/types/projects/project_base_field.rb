# frozen_string_literal: true

module Types
  module Projects
    # rubocop: disable GraphQL/GraphqlName -- Not a type
    # rubocop: disable Graphql/AuthorizeTypes -- Not a type
    class ProjectBaseField < ::Types::BaseField
      def initialize(**kwargs, &block)
        kwargs[:authorize] = :read_project

        super
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
    # rubocop: enable GraphQL/GraphqlName
  end
end
