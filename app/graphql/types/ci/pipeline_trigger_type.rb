# frozen_string_literal: true

module Types
  module Ci
    class PipelineTriggerType < BaseObject
      graphql_name 'PipelineTrigger'

      present_using ::Ci::TriggerPresenter
      connection_type_class Types::CountableConnectionType

      authorize :manage_trigger

      field :can_access_project, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates if the pipeline trigger token has access to the project.',
        method: :can_access_project?

      field :description, GraphQL::Types::String,
        null: true,
        description: 'Description of the pipeline trigger token.'

      field :has_token_exposed, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates if the token is exposed.',
        method: :has_token_exposed?

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the pipeline trigger token.'

      field :last_used, Types::TimeType,
        null: true,
        description: 'Timestamp of the last usage of the pipeline trigger token.'

      field :expires_at, Types::TimeType,
        null: true,
        description: 'Timestamp of when the pipeline trigger token expires.'

      field :owner, Types::UserType,
        null: false,
        description: 'Owner of the pipeline trigger token.'

      field :token, GraphQL::Types::String,
        null: false,
        description: 'Value of the pipeline trigger token.'
    end
  end
end
