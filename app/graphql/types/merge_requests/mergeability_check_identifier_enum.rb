# frozen_string_literal: true

module Types
  module MergeRequests
    class MergeabilityCheckIdentifierEnum < BaseEnum
      graphql_name 'MergeabilityCheckIdentifier'
      description 'Representation of mergeability check identifier.'

      MergeRequest.all_mergeability_checks.each do |check_class|
        identifier = check_class.identifier.to_s

        value identifier.upcase,
          value: identifier,
          description: check_class.description
      end
    end
  end
end
