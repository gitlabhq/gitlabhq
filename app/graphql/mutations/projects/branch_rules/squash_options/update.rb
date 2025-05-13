# frozen_string_literal: true

module Mutations
  module Projects
    module BranchRules
      module SquashOptions
        class Update < BaseMutation
          graphql_name 'BranchRuleSquashOptionUpdate'
          description 'Update a squash option for a branch rule'

          authorize :update_squash_option
          argument :branch_rule_id, ::Types::GlobalIDType[::Projects::BranchRule],
            required: true,
            description: 'Global ID of the branch rule.'

          argument :squash_option, ::Types::Projects::BranchRules::SquashOptionSettingEnum,
            required: true,
            description: 'Squash option after mutation.'

          field :squash_option,
            type: ::Types::Projects::BranchRules::SquashOptionType,
            null: true,
            description: 'Updated squash option after mutation.'

          def resolve(branch_rule_id:, squash_option:)
            branch_rule = authorized_find!(id: branch_rule_id)

            service_response = ::Projects::BranchRules::SquashOptions::UpdateService.new(
              branch_rule,
              squash_option: squash_option,
              current_user: current_user
            ).execute

            {
              squash_option: (service_response.payload if service_response.success?),
              errors: service_response.errors
            }
          end
        end
      end
    end
  end
end

Mutations::Projects::BranchRules::SquashOptions::Update.prepend_mod
