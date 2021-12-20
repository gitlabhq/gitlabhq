# frozen_string_literal: true

module Types
  class BaseEdge < GraphQL::Types::Relay::BaseEdge
    field_class Types::BaseField
  end
end
