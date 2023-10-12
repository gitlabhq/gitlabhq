# frozen_string_literal: true

module Types
  module MergeRequests
    class MergeabilityCheckType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'MergeRequestMergeabilityCheck'
      description 'Mergeability check of the merge request.'

      field :identifier,
        ::Types::MergeRequests::MergeabilityCheckIdentifierEnum,
        null: false,
        description: 'Identifier of the mergeability check.'

      field :status,
        ::Types::MergeRequests::MergeabilityCheckStatusEnum,
        null: false,
        description: 'Status of the mergeability check.'

      def status
        object.status.to_s
      end

      def identifier
        object.identifier.to_s
      end
    end
  end
end
