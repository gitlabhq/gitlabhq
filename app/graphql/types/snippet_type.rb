# frozen_string_literal: true

module Types
  class SnippetType < BaseObject
    graphql_name 'Snippet'
    description 'Represents a snippet entry'

    implements(Types::Notes::NoteableInterface)

    present_using SnippetPresenter

    authorize :read_snippet

    expose_permissions Types::PermissionTypes::Snippet

    field :id, Types::GlobalIDType[::Snippet],
          description: 'ID of the snippet.',
          null: false

    field :title, GraphQL::STRING_TYPE,
          description: 'Title of the snippet.',
          null: false

    field :project, Types::ProjectType,
          description: 'The project the snippet is associated with.',
          null: true,
          authorize: :read_project

    # Author can be nil in some scenarios. For example,
    # when the admin setting restricted visibility
    # level is set to public
    field :author, Types::UserType,
          description: 'The owner of the snippet.',
          null: true

    field :file_name, GraphQL::STRING_TYPE,
          description: 'File Name of the snippet.',
          null: true

    field :description, GraphQL::STRING_TYPE,
          description: 'Description of the snippet.',
          null: true

    field :visibility_level, Types::VisibilityLevelsEnum,
          description: 'Visibility Level of the snippet.',
          null: false

    field :created_at, Types::TimeType,
          description: 'Timestamp this snippet was created.',
          null: false

    field :updated_at, Types::TimeType,
          description: 'Timestamp this snippet was updated.',
          null: false

    field :web_url, type: GraphQL::STRING_TYPE,
          description: 'Web URL of the snippet.',
          null: false

    field :raw_url, type: GraphQL::STRING_TYPE,
          description: 'Raw URL of the snippet.',
          null: false

    field :blobs, type: Types::Snippets::BlobType.connection_type,
          description: 'Snippet blobs.',
          calls_gitaly: true,
          null: true,
          resolver: Resolvers::Snippets::BlobsResolver

    field :ssh_url_to_repo, type: GraphQL::STRING_TYPE,
          description: 'SSH URL to the snippet repository.',
          calls_gitaly: true,
          null: true

    field :http_url_to_repo, type: GraphQL::STRING_TYPE,
          description: 'HTTP URL to the snippet repository.',
          calls_gitaly: true,
          null: true

    markdown_field :description_html, null: true, method: :description

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
    end
  end
end
