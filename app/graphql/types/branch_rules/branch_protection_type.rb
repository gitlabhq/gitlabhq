# frozen_string_literal: true

module Types
  module BranchRules
    class BranchProtectionType < BaseObject
      graphql_name 'BranchProtection'
      description 'Branch protection details for a branch rule.'
      accepts ::ProtectedBranch
      authorize :read_protected_branch

      field :merge_access_levels,
        type: Types::BranchProtections::MergeAccessLevelType.connection_type,
        null: true,
        description: 'Details about who can merge when the branch is the source branch.'

      field :push_access_levels,
        type: Types::BranchProtections::PushAccessLevelType.connection_type,
        null: true,
        description: 'Details about who can push when the branch is the source branch.'

      field :allow_force_push,
        type: GraphQL::Types::Boolean,
        null: false,
        description: 'Toggle force push to the branch for users with write access.'
    end
  end
end

Types::BranchRules::BranchProtectionType.prepend_mod_with('Types::BranchRules::BranchProtectionType')
