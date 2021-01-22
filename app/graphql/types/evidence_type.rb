# frozen_string_literal: true

module Types
  class EvidenceType < BaseObject
    graphql_name 'ReleaseEvidence'
    description 'Evidence for a release'

    authorize :download_code

    present_using Releases::EvidencePresenter

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the evidence.'
    field :sha, GraphQL::STRING_TYPE, null: true,
          description: 'SHA1 ID of the evidence hash.'
    field :filepath, GraphQL::STRING_TYPE, null: true,
          description: 'URL from where the evidence can be downloaded.'
    field :collected_at, Types::TimeType, null: true,
          description: 'Timestamp when the evidence was collected.'
  end
end
