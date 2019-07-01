# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes
    class DiffPositionBaseInputType < BaseInputObject
      argument :head_sha, GraphQL::STRING_TYPE, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :head_sha)
      argument :base_sha,  GraphQL::STRING_TYPE, required: false,
               description: copy_field_description(Types::Notes::DiffPositionType, :base_sha)
      argument :start_sha, GraphQL::STRING_TYPE, required: true,
               description: copy_field_description(Types::Notes::DiffPositionType, :start_sha)

      argument :paths,
               Types::DiffPathsInputType,
               required: true,
               description: 'The paths of the file that was changed. ' \
                            'Both of the properties of this input are optional, but at least one of them is required'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
