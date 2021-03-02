# frozen_string_literal: true

module Types
  module Notes
    class DiffPositionInputType < DiffPositionBaseInputType
      graphql_name 'DiffPositionInput'

      argument :old_line, GraphQL::INT_TYPE, required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :old_line)
      argument :new_line, GraphQL::INT_TYPE, required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :new_line)
    end
  end
end
