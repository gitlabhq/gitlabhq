# frozen_string_literal: true

module Types
  module Notes
    class DiffPositionBaseInputType < BaseInputObject
      argument :base_sha, GraphQL::Types::String, required: false,
        description: copy_field_description(Types::DiffRefsType, :base_sha)
      argument :head_sha, GraphQL::Types::String, required: true,
        description: copy_field_description(Types::DiffRefsType, :head_sha)
      argument :start_sha, GraphQL::Types::String, required: true,
        description: copy_field_description(Types::DiffRefsType, :start_sha)

      argument :paths,
        Types::DiffPathsInputType,
        required: true,
        description: 'The paths of the file that was changed. ' \
          'Both of the properties of this input are optional, but at least one of them is required'
    end
  end
end
