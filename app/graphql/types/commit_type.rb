# frozen_string_literal: true

module Types
  class CommitType < BaseObject
    graphql_name 'Commit'

    authorize :download_code

    present_using CommitPresenter

    field :id, type: GraphQL::Types::ID, null: false,
          description: 'ID (global ID) of the commit.'
    field :sha, type: GraphQL::Types::String, null: false,
          description: 'SHA1 ID of the commit.'
    field :short_id, type: GraphQL::Types::String, null: false,
          description: 'Short SHA1 ID of the commit.'
    field :title, type: GraphQL::Types::String, null: true, calls_gitaly: true,
          description: 'Title of the commit message.'
    markdown_field :title_html, null: true
    field :description, type: GraphQL::Types::String, null: true,
          description: 'Description of the commit message.'
    markdown_field :description_html, null: true
    field :message, type: GraphQL::Types::String, null: true,
          description: 'Raw commit message.'
    field :authored_date, type: Types::TimeType, null: true,
          description: 'Timestamp of when the commit was authored.'
    field :web_url, type: GraphQL::Types::String, null: false,
          description: 'Web URL of the commit.'
    field :web_path, type: GraphQL::Types::String, null: false,
          description: 'Web path of the commit.'
    field :signature_html, type: GraphQL::Types::String, null: true, calls_gitaly: true,
          description: 'Rendered HTML of the commit signature.'
    field :author_name, type: GraphQL::Types::String, null: true,
          description: 'Commit authors name.'
    field :author_gravatar, type: GraphQL::Types::String, null: true,
          description: 'Commit authors gravatar.'

    # models/commit lazy loads the author by email
    field :author, type: Types::UserType, null: true,
          description: 'Author of the commit.'

    field :pipelines,
          null: true,
          description: 'Pipelines of the commit ordered latest first.',
          resolver: Resolvers::CommitPipelinesResolver

    def author_gravatar
      GravatarService.new.execute(object.author_email, 40)
    end
  end
end
