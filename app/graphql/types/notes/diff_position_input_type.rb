# frozen_string_literal: true

module Types
  module Notes
    class DiffPositionInputType < DiffPositionBaseInputType
      graphql_name 'DiffPositionInput'

      argument :new_line, GraphQL::Types::Int, required: false,
        description: "#{copy_field_description(Types::Notes::DiffPositionType, :new_line)} Please see the [REST API Documentation](https://docs.gitlab.com/ee/api/discussions.html#create-a-new-thread-in-the-merge-request-diff) for more information on how to use this field."
      argument :old_line, GraphQL::Types::Int, required: false,
        description: "#{copy_field_description(Types::Notes::DiffPositionType, :old_line)} Please see the [REST API Documentation](https://docs.gitlab.com/ee/api/discussions.html#create-a-new-thread-in-the-merge-request-diff) for more information on how to use this field."
    end
  end
end
