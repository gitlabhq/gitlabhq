# frozen_string_literal: true

module Types
  module Ci
    class PipelineType < BaseObject
      graphql_name 'Pipeline'

      authorize :read_pipeline

      expose_permissions Types::PermissionTypes::Ci::Pipeline

      field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :iid, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions

      field :sha, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :before_sha, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
      field :status, PipelineStatusEnum, null: false # rubocop:disable Graphql/Descriptions
      field :detailed_status, # rubocop:disable Graphql/Descriptions
            Types::Ci::DetailedStatusType,
            null: false,
            resolve: -> (obj, _args, ctx) { obj.detailed_status(ctx[:current_user]) }
      field :duration,
            GraphQL::INT_TYPE,
            null: true,
            description: "Duration of the pipeline in seconds"
      field :coverage,
            GraphQL::FLOAT_TYPE,
            null: true,
            description: "Coverage percentage"
      field :created_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
      field :updated_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
      field :started_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
      field :finished_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
      field :committed_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions

      # TODO: Add triggering user as a type
    end
  end
end
