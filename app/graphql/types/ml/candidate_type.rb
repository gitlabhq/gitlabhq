# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class CandidateType < ::Types::BaseObject
      graphql_name 'MlCandidate'
      description 'Candidate for a model version in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      present_using ::Ml::CandidatePresenter

      field :id, ::Types::GlobalIDType[::Ml::Candidate], null: false, description: 'ID of the candidate.'

      field :name, ::GraphQL::Types::String,
        null: true,
        description: 'Name of the candidate.'

      field :iid, ::GraphQL::Types::Int,
        null: false,
        description: 'IID of the candidate scoped to project.'

      field :eid, ::GraphQL::Types::String,
        null: false,
        description: 'MLflow uuid for the candidate.'

      field :status, ::GraphQL::Types::String,
        null: true,
        description: 'Candidate status.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'

      field :params, ::Types::Ml::CandidateParamType.connection_type,
        null: false,
        description: 'Parameters for the candidate.'

      field :metrics, ::Types::Ml::CandidateMetricType.connection_type,
        null: false,
        description: 'Metrics for the candidate.'

      field :metadata, ::Types::Ml::CandidateMetadataType.connection_type,
        null: false,
        description: 'Metadata entries for the candidate.'

      field :ci_job, ::Types::Ci::JobType,
        null: true,
        description: 'CI information about the job that created the candidate.'

      field :creator, ::Types::UserType,
        null: true,
        description: 'User that created the candidate.'

      field :_links, ::Types::Ml::CandidateLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the candidate.'

      def ci_job
        return unless object.from_ci? && Ability.allowed?(current_user, :read_build, object.ci_build)

        object.ci_build
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
