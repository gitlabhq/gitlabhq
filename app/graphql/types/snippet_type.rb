# frozen_string_literal: true

module Types
  class SnippetType < BaseObject
    graphql_name 'Snippet'
    description 'Represents a snippet entry'

    implements(Types::Notes::NoteableType)

    present_using SnippetPresenter

    authorize :read_snippet

    expose_permissions Types::PermissionTypes::Snippet

    field :id, GraphQL::ID_TYPE,
          description: 'Id of the snippet',
          null: false

    field :title, GraphQL::STRING_TYPE,
          description: 'Title of the snippet',
          null: false

    field :project, Types::ProjectType,
          description: 'The project the snippet is associated with',
          null: true,
          authorize: :read_project,
          resolve: -> (snippet, args, context) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, snippet.project_id).find }

    field :author, Types::UserType,
          description: 'The owner of the snippet',
          null: false,
          resolve: -> (snippet, args, context) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, snippet.author_id).find }

    field :file_name, GraphQL::STRING_TYPE,
          description: 'File Name of the snippet',
          null: true

    field :content, GraphQL::STRING_TYPE,
          description: 'Content of the snippet',
          null: false

    field :description, GraphQL::STRING_TYPE,
          description: 'Description of the snippet',
          null: true

    field :visibility, GraphQL::STRING_TYPE,
          description: 'Visibility of the snippet',
          null: false

    field :created_at, Types::TimeType,
          description: 'Timestamp this snippet was created',
          null: false

    field :updated_at, Types::TimeType,
          description: 'Timestamp this snippet was updated',
          null: false

    field :web_url, type: GraphQL::STRING_TYPE,
          description: 'Web URL of the snippet',
          null: false

    field :raw_url, type: GraphQL::STRING_TYPE,
          description: 'Raw URL of the snippet',
          null: false

    markdown_field :description_html, null: true, method: :description
  end
end
