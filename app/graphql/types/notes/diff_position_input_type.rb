# frozen_string_literal: true

module Types
  module Notes
    class DiffPositionInputType < DiffPositionBaseInputType
      graphql_name 'DiffPositionInput'

      argument :new_line, GraphQL::Types::Int, required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :new_line)
      argument :old_line, GraphQL::Types::Int, required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :old_line)
    end
  end
end
