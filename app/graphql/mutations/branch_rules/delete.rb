# frozen_string_literal: true

module Mutations
  module BranchRules
    class Delete < BaseMutation
      graphql_name 'BranchRuleDelete'

      authorize :destroy_branch_rule

      argument :id, ::Types::GlobalIDType[::Projects::BranchRule],
        required: true,
        description: 'Global ID of the branch rule to destroy.'

      field :branch_rule,
        ::Types::Projects::BranchRuleType,
        null: true,
        description: 'Branch rule after mutation.'

      def resolve(id:)
        branch_rule = authorized_find!(id: id)

        response = ::BranchRules::DestroyService.new(branch_rule, current_user).execute

        { branch_rule: (branch_rule if response.error?), errors: response.errors }
      rescue Gitlab::Access::AccessDeniedError
        raise_resource_not_available_error!
      end
    end
  end
end
