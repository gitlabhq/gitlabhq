# frozen_string_literal: true

module Types
  module Notes
    class DiffImagePositionInputType < DiffPositionBaseInputType
      graphql_name 'DiffImagePositionInput'

      argument :height,
        GraphQL::Types::Int,
        required: true,
        description: copy_field_description(Types::Notes::DiffPositionType, :height)
      argument :width,
        GraphQL::Types::Int,
        required: true,
        description: copy_field_description(Types::Notes::DiffPositionType, :width)
      argument :x,
        GraphQL::Types::Int,
        required: true,
        description: copy_field_description(Types::Notes::DiffPositionType, :x)
      argument :y,
        GraphQL::Types::Int,
        required: true,
        description: copy_field_description(Types::Notes::DiffPositionType, :y)
    end
  end
end
