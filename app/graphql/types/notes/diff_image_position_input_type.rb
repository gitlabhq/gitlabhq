# frozen_string_literal: true

module Types
  module Notes
    class DiffImagePositionInputType < DiffPositionBaseInputType
      graphql_name 'DiffImagePositionInput'

      argument :x, GraphQL::Types::Int, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :x)
      argument :y, GraphQL::Types::Int, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :y)
      argument :width, GraphQL::Types::Int, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :width)
      argument :height, GraphQL::Types::Int, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :height)
    end
  end
end
