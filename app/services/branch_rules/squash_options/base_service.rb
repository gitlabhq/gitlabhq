# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- TODO include branch rules bounded context
module BranchRules
  module SquashOptions
    class BaseService < ::BranchRules::BaseService
      private

      delegate :protected_branch, to: :branch_rule, allow_nil: true, private: true

      def execute_on_branch_rule
        ServiceResponse.error(message: 'Squash options are not supported for this branch rule')
      end

      def execute_on_all_branches_rule
        ServiceResponse.error(
          message: 'Squash options for all branches can only be changed using the update mutation'
        )
      end

      def execute_on_all_protected_branches_rule
        ServiceResponse.error(
          message: 'All protected branch rules cannot configure squash options',
          payload: { errors: ['All protected branches not allowed'] },
          reason: :unprocessable_entity
        )
      end

      def success_response
        ServiceResponse.success(payload: branch_rule.squash_option)
      end

      def squash_option
        params[:squash_option]
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts

::BranchRules::SquashOptions::BaseService.prepend_mod
