# frozen_string_literal: true

module Types
  module Ci
    class PipelineType < BaseObject
      graphql_name 'Pipeline'

      authorize :read_pipeline

      expose_permissions Types::PermissionTypes::Ci::Pipeline

      field :id, GraphQL::ID_TYPE, null: false
      field :iid, GraphQL::STRING_TYPE, null: false

      field :sha, GraphQL::STRING_TYPE, null: false
      field :before_sha, GraphQL::STRING_TYPE, null: true
      field :status, PipelineStatusEnum, null: false
      field :detailed_status,
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
      field :created_at, Types::TimeType, null: false
      field :updated_at, Types::TimeType, null: false
      field :started_at, Types::TimeType, null: true
      field :finished_at, Types::TimeType, null: true
      field :committed_at, Types::TimeType, null: true

      # TODO: Add triggering user as a type
    end
  end
end
