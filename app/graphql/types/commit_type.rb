# frozen_string_literal: true

module Types
  class CommitType < BaseObject
    graphql_name 'Commit'

    authorize :download_code

    present_using CommitPresenter

    field :id, type: GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :sha, type: GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :title, type: GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :description, type: GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :message, type: GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :authored_date, type: Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :web_url, type: GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :signature_html, type: GraphQL::STRING_TYPE,
      null: true, calls_gitaly: true, description: 'Rendered html for the commit signature'

    # models/commit lazy loads the author by email
    field :author, type: Types::UserType, null: true # rubocop:disable Graphql/Descriptions

    field :latest_pipeline,
          type: Types::Ci::PipelineType,
          null: true,
          description: "Latest pipeline for this commit",
          resolve: -> (obj, ctx, args) do
            Gitlab::Graphql::Loaders::PipelineForShaLoader.new(obj.project, obj.sha).find_last
          end
  end
end
