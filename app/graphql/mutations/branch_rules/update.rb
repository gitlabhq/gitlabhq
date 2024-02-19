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

      field :branch_rule,
        Types::Projects::BranchRuleType,
        null: true,
        description: 'Branch rule after mutation.'

      def resolve(id:, name:)
        branch_rule = authorized_find!(id: id)

        response = ::BranchRules::UpdateService.new(branch_rule, current_user, { name: name }).execute

        { branch_rule: branch_rule, errors: response.errors }
      end
    end
  end
end
