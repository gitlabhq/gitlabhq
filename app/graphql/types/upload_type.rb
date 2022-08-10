# frozen_string_literal: true

module Types
  class UploadType < BaseObject
    graphql_name 'FileUpload'

    authorize :read_upload

    field :id, Types::GlobalIDType[::Upload],
      null: false,
      description: 'Global ID of the upload.'
    field :path, GraphQL::Types::String,
      null: false,
      description: 'Path of the upload.'
    field :size, GraphQL::Types::Int,
      null: false,
      description: 'Size of the upload in bytes.'
  end
end
