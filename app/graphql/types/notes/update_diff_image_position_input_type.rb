# frozen_string_literal: true

module Types
  module Notes
    # InputType used for updateImageDiffNote mutation.
    #
    # rubocop: disable Graphql/AuthorizeTypes
    class UpdateDiffImagePositionInputType < BaseInputObject
      graphql_name 'UpdateDiffImagePositionInput'

      argument :x, GraphQL::INT_TYPE,
               required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :x)

      argument :y, GraphQL::INT_TYPE,
               required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :y)

      argument :width, GraphQL::INT_TYPE,
               required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :width)

      argument :height, GraphQL::INT_TYPE,
               required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :height)
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
