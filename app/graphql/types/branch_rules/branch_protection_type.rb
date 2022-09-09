# frozen_string_literal: true

module Types
  module BranchRules
    class BranchProtectionType < BaseObject
      graphql_name 'BranchProtection'
      description 'Branch protection details for a branch rule.'
      accepts ::ProtectedBranch
      authorize :read_protected_branch

      field :allow_force_push,
            type: GraphQL::Types::Boolean,
            null: false,
            description: 'Toggle force push to the branch for users with write access.'
    end
  end
end
