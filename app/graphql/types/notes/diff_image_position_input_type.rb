# frozen_string_literal: true

module Types
  module Notes
    class DiffImagePositionInputType < DiffPositionBaseInputType
      graphql_name 'DiffImagePositionInput'

      argument :x, GraphQL::INT_TYPE, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :x)
      argument :y, GraphQL::INT_TYPE, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :y)
      argument :width, GraphQL::INT_TYPE, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :width)
      argument :height, GraphQL::INT_TYPE, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :height)
    end
  end
end
