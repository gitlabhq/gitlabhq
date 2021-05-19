# frozen_string_literal: true

module Types
  module Ci
    class RunnerType < BaseObject
      graphql_name 'CiRunner'
      authorize :read_runner

      field :id, ::Types::GlobalIDType[::Ci::Runner], null: false,
            description: 'ID of the runner.'
      field :description, GraphQL::STRING_TYPE, null: true,
            description: 'Description of the runner.'
      field :contacted_at, Types::TimeType, null: true,
            description: 'Last contact from the runner.',
            method: :contacted_at
      field :maximum_timeout, GraphQL::INT_TYPE, null: true,
            description: 'Maximum timeout (in seconds) for jobs processed by the runner.'
      field :access_level, ::Types::Ci::RunnerAccessLevelEnum, null: false,
            description: 'Access level of the runner.'
      field :active, GraphQL::BOOLEAN_TYPE, null: false,
            description: 'Indicates the runner is allowed to receive jobs.'
      field :status, ::Types::Ci::RunnerStatusEnum, null: false,
            description: 'Status of the runner.'
      field :version, GraphQL::STRING_TYPE, null: false,
            description: 'Version of the runner.'
      field :short_sha, GraphQL::STRING_TYPE, null: true,
            description: %q(First eight characters of the runner's token used to authenticate new job requests. Used as the runner's unique ID.)
      field :revision, GraphQL::STRING_TYPE, null: false,
            description: 'Revision of the runner.'
      field :locked, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates the runner is locked.'
      field :run_untagged, GraphQL::BOOLEAN_TYPE, null: false,
            description: 'Indicates the runner is able to run untagged jobs.'
      field :ip_address, GraphQL::STRING_TYPE, null: false,
            description: 'IP address of the runner.'
      field :runner_type, ::Types::Ci::RunnerTypeEnum, null: false,
            description: 'Type of the runner.'
      field :tag_list, [GraphQL::STRING_TYPE], null: true,
            description: 'Tags associated with the runner.'
    end
  end
end
