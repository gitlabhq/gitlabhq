# frozen_string_literal: true

module Types
  module Namespaces
    # rubocop: disable GraphQL/GraphqlName -- Not a type
    # rubocop: disable Graphql/AuthorizeTypes -- Not a type
    class GroupBaseField < ::Types::BaseField
      def initialize(**kwargs, &block)
        kwargs[:authorize] = :read_group

        super
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
    # rubocop: enable GraphQL/GraphqlName
  end
end
