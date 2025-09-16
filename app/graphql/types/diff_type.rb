# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class DiffType < BaseObject
    graphql_name 'Diff'

    field :a_mode, GraphQL::Types::String, null: true,
      description: 'Old file mode of the file.'
    field :b_mode, GraphQL::Types::String, null: true,
      description: 'New file mode of the file.'
    field :collapsed, GraphQL::Types::String, null: true,
      description: 'File diffs are excluded but can be fetched on request.',
      method: :collapsed?
    field :deleted_file, GraphQL::Types::String, null: true,
      description: 'Indicates if the file has been removed. '
    field :diff, GraphQL::Types::String, null: true,
      description: 'Diff representation of the changes made to the file.'
    field :new_file, GraphQL::Types::String, null: true,
      description: 'Indicates if the file has just been added. '
    field :new_path, GraphQL::Types::String, null: true,
      description: 'New path of the file.'
    field :old_path, GraphQL::Types::String, null: true,
      description: 'Old path of the file.'
    field :renamed_file, GraphQL::Types::String, null: true,
      description: 'Indicates if the file has been renamed.'
    field :too_large, GraphQL::Types::String, null: true,
      description: 'File diffs are excluded and cannot be retrieved.',
      method: :too_large?
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
