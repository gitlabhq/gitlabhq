# frozen_string_literal: true

module Types
  class CommitType < BaseObject
    graphql_name 'Commit'

    authorize :download_code

    present_using CommitPresenter

    field :id, type: GraphQL::ID_TYPE, null: false
    field :sha, type: GraphQL::STRING_TYPE, null: false
    field :title, type: GraphQL::STRING_TYPE, null: true
    field :description, type: GraphQL::STRING_TYPE, null: true
    field :message, type: GraphQL::STRING_TYPE, null: true
    field :authored_date, type: Types::TimeType, null: true
    field :web_url, type: GraphQL::STRING_TYPE, null: false

    # models/commit lazy loads the author by email
    field :author, type: Types::UserType, null: true

    field :latest_pipeline,
          type: Types::Ci::PipelineType,
          null: true,
          description: "Latest pipeline for this commit",
          resolve: -> (obj, ctx, args) do
            Gitlab::Graphql::Loaders::PipelineForShaLoader.new(obj.project, obj.sha).find_last
          end
  end
end
