# frozen_string_literal: true

module Types
  module CustomIntrospection # rubocop:disable Gitlab/BoundedContexts -- module is used to override GraphQL's default introspection module
    class DynamicFields < GraphQL::Introspection::DynamicFields # rubocop:disable GraphQL/GraphqlName,Graphql/AuthorizeTypes -- not needed for dynamic fields
      field :__typename, String,
        description: 'Name of the type.',
        null: false, dynamic_introspection: true, resolve_each: true, complexity: 0.2
    end
  end
end
