# frozen_string_literal: true

module Types
  class EvidenceType < BaseObject
    graphql_name 'ReleaseEvidence'
    description 'Evidence for a release'

    authorize :read_release_evidence

    present_using Releases::EvidencePresenter

    field :collected_at, Types::TimeType, null: true,
      description: 'Timestamp when the evidence was collected.'
    field :filepath, GraphQL::Types::String, null: true,
      description: 'URL from where the evidence can be downloaded.'
    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the evidence.'
    field :sha, GraphQL::Types::String, null: true,
      description: 'SHA1 ID of the evidence hash.'
  end
end
