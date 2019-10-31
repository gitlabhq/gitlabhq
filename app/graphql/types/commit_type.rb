# frozen_string_literal: true

module Types
  class CommitType < BaseObject
    graphql_name 'Commit'

    authorize :download_code

    present_using CommitPresenter

    field :id, type: GraphQL::ID_TYPE, null: false,
          description: 'ID (global ID) of the commit'
    field :sha, type: GraphQL::STRING_TYPE, null: false,
          description: 'SHA1 ID of the commit'
    field :title, type: GraphQL::STRING_TYPE, null: true,
          description: 'Title of the commit message'
    field :description, type: GraphQL::STRING_TYPE, null: true,
          description: 'Description of the commit message'
    field :message, type: GraphQL::STRING_TYPE, null: true,
          description: 'Raw commit message'
    field :authored_date, type: Types::TimeType, null: true,
          description: 'Timestamp of when the commit was authored'
    field :web_url, type: GraphQL::STRING_TYPE, null: false,
          description: 'Web URL of the commit'
    field :signature_html, type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true,
          description: 'Rendered HTML of the commit signature'

    # models/commit lazy loads the author by email
    field :author, type: Types::UserType, null: true,
          description: 'Author of the commit'

    field :latest_pipeline,
          type: Types::Ci::PipelineType,
          null: true,
          description: "Latest pipeline of the commit",
          resolve: -> (obj, ctx, args) do
            Gitlab::Graphql::Loaders::PipelineForShaLoader.new(obj.project, obj.sha).find_last
          end
  end
end
