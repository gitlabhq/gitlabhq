module Types
  class BaseObject < GraphQL::Schema::Object
    prepend Gitlab::Graphql::Present

    field_class Types::BaseField
  end
end
