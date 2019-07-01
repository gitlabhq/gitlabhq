# frozen_string_literal: true

module Types
  class BaseInputObject < GraphQL::Schema::InputObject
    prepend Gitlab::Graphql::CopyFieldDescription
  end
end
