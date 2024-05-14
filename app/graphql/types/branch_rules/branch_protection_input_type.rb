# frozen_string_literal: true

module Types
  module BranchRules
    class BranchProtectionInputType < Types::BaseInputObject
      argument :merge_access_levels, [Types::BranchProtections::MergeAccessLevelInputType],
        required: false,
        default_value: [],
        replace_null_with_default: true,
        description: 'Details about who can merge into the branch rule target.'

      argument :push_access_levels, [Types::BranchProtections::PushAccessLevelInputType],
        required: false,
        default_value: [],
        replace_null_with_default: true,
        description: 'Details about who can push to the branch rule target.'

      argument :allow_force_push, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        replace_null_with_default: true,
        description: 'Allows users with write access to the branch rule target to force push changes.'

      def prepare
        to_h
      end
    end
  end
end

Types::BranchRules::BranchProtectionInputType.prepend_mod
