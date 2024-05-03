# frozen_string_literal: true

module Mutations
  module BranchRules
    class Update < BaseMutation
      graphql_name 'BranchRuleUpdate'

      authorize :update_branch_rule

      argument :id, ::Types::GlobalIDType[::Projects::BranchRule],
        required: true,
        description: 'Global ID of the branch rule to update.'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Branch name, with wildcards, for the branch rules.'

      argument :branch_protection, Types::BranchRules::BranchProtectionInputType,
        required: false,
        description: 'Branch protections configured for the branch rule.'

      field :branch_rule,
        Types::Projects::BranchRuleType,
        null: true,
        description: 'Branch rule after mutation.'

      def resolve(id:, **params)
        branch_rule = authorized_find!(id: id)

        response = ::BranchRules::UpdateService.new(branch_rule, current_user, params).execute

        { branch_rule: (branch_rule if response.success?), errors: response.errors }
      end
    end
  end
end
