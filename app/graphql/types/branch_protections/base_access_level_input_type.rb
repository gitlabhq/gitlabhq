# frozen_string_literal: true

module Types
  module BranchProtections
    class BaseAccessLevelInputType < Types::BaseInputObject
      argument :access_level, type: GraphQL::Types::Int,
        required: false,
        description: 'Access level allowed to perform action.'
    end
  end
end

Types::BranchProtections::BaseAccessLevelInputType.prepend_mod
