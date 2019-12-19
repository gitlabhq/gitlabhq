# frozen_string_literal: true

module Types
  module Ci
    class PipelineType < BaseObject
      graphql_name 'Pipeline'

      authorize :read_pipeline

      expose_permissions Types::PermissionTypes::Ci::Pipeline

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the pipeline'
      field :iid, GraphQL::STRING_TYPE, null: false,
            description: 'Internal ID of the pipeline'

      field :sha, GraphQL::STRING_TYPE, null: false,
            description: "SHA of the pipeline's commit"
      field :before_sha, GraphQL::STRING_TYPE, null: true,
            description: "Base SHA of the source branch"
      field :status, PipelineStatusEnum, null: false,
            description: "Status of the pipeline (#{::Ci::Pipeline.all_state_names.compact.join(', ').upcase})"
      field :detailed_status, Types::Ci::DetailedStatusType, null: false,
            description: 'Detailed status of the pipeline',
            resolve: -> (obj, _args, ctx) { obj.detailed_status(ctx[:current_user]) }
      field :duration, GraphQL::INT_TYPE, null: true,
            description: "Duration of the pipeline in seconds"
      field :coverage, GraphQL::FLOAT_TYPE, null: true,
            description: "Coverage percentage"
      field :created_at, Types::TimeType, null: false,
            description: "Timestamp of the pipeline's creation"
      field :updated_at, Types::TimeType, null: false,
            description: "Timestamp of the pipeline's last activity"
      field :started_at, Types::TimeType, null: true,
            description: 'Timestamp when the pipeline was started'
      field :finished_at, Types::TimeType, null: true,
            description: "Timestamp of the pipeline's completion"
      field :committed_at, Types::TimeType, null: true,
            description: "Timestamp of the pipeline's commit"

      # TODO: Add triggering user as a type
    end
  end
end
