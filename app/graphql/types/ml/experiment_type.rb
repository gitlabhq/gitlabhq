# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes -- authorization in FindExperimentResolver / ExperimentDetailResolver
  module Ml
    class ExperimentType < ::Types::BaseObject
      graphql_name 'MlExperiment'
      description 'Machine learning experiment in model experiments'

      connection_type_class Types::LimitedCountableConnectionType

      present_using ::Ml::ExperimentPresenter

      field :id, ::Types::GlobalIDType[::Ml::Experiment], null: false,
        description: 'ID of the experiment.'

      field :name, ::GraphQL::Types::String, null: false, description: 'Name of the experiment.'

      field :created_at, ::Types::TimeType, null: false,
        description: 'Timestamp of when the experiment was created.'

      field :updated_at, ::Types::TimeType, null: false,
        description: 'Timestamp of when the experiment was updated.'

      field :candidate_count, ::GraphQL::Types::Int, null: false,
        description: 'Number of candidates in the experiment.'

      field :path, ::GraphQL::Types::String, null: false,
        description: 'Web URL of the experiment.'

      field :creator, ::Types::UserType, null: true,
        description: 'User who created the experiment.'

      field :model_id, ::Types::GlobalIDType[::Ml::Model], null: true, description: 'ID of the model.'

      field :candidates, ::Types::Ml::CandidateType.connection_type, null: true,
        description: 'Candidates of the experiment.'
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
