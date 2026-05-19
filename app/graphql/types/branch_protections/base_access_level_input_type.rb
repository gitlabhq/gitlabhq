# frozen_string_literal: true

module Types
  module BranchProtections
    class BaseAccessLevelInputType < Types::BaseInputObject
      # rubocop:disable Graphql::AccessLevelEnum -- Introduced before the cop
      argument :access_level, type: GraphQL::Types::Int,
        required: false,
        description: 'Access level allowed to perform action.'
      # rubocop:enable Graphql::AccessLevelEnum
    end
  end
end

Types::BranchProtections::BaseAccessLevelInputType.prepend_mod
