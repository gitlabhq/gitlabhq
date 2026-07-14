# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- TODO include branch rules bounded context
module BranchRules
  module SquashOptions
    class UpdateService < BaseService
      private

      def authorized?
        can?(current_user, :update_squash_option, branch_rule)
      end

      def execute_on_all_branches_rule
        result = ::Projects::UpdateService.new(
          project,
          current_user,
          project_setting_attributes: { squash_option: squash_option }
        ).execute

        return ServiceResponse.error(message: result[:message]) unless result[:status] == :success

        success_response
      end

      def execute_on_branch_rule
        ServiceResponse.error(message: 'Updating BranchRule not supported')
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts

::BranchRules::SquashOptions::UpdateService.prepend_mod
