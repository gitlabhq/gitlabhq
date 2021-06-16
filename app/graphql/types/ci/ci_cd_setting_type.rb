# frozen_string_literal: true

module Types
  module Ci
    class CiCdSettingType < BaseObject
      graphql_name 'ProjectCiCdSetting'

      authorize :admin_project

      field :merge_pipelines_enabled, GraphQL::BOOLEAN_TYPE, null: true,
        description: 'Whether merge pipelines are enabled.',
        method: :merge_pipelines_enabled?
      field :merge_trains_enabled, GraphQL::BOOLEAN_TYPE, null: true,
        description: 'Whether merge trains are enabled.',
        method: :merge_trains_enabled?
      field :keep_latest_artifact, GraphQL::BOOLEAN_TYPE, null: true,
        description: 'Whether to keep the latest builds artifacts.',
        method: :keep_latest_artifacts_available?
      field :job_token_scope_enabled, GraphQL::BOOLEAN_TYPE, null: true,
        description: 'Indicates CI job tokens generated in this project have restricted access to resources.',
        method: :job_token_scope_enabled?
      field :project, Types::ProjectType, null: true,
        description: 'Project the CI/CD settings belong to.'
    end
  end
end
