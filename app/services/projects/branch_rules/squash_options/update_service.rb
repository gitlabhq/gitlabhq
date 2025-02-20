# frozen_string_literal: true

module Projects
  module BranchRules
    module SquashOptions
      class UpdateService
        AUTHORIZATION_ERROR_MESSAGE = 'Not authorized'
        NOT_SUPPORTED_ERROR_MESSAGE = 'Updating BranchRule not supported'

        def initialize(branch_rule, squash_option:, current_user:)
          @branch_rule = branch_rule
          @squash_option = squash_option
          @current_user = current_user
        end

        def execute
          return ServiceResponse.error(message: AUTHORIZATION_ERROR_MESSAGE) unless authorized?

          if branch_rule.is_a?(::Projects::AllBranchesRule)
            execute_on_all_branches_rule
          else
            execute_on_branch_rule
          end
        end

        private

        attr_reader :branch_rule, :squash_option, :current_user

        def execute_on_all_branches_rule
          result = Projects::UpdateService.new(project, current_user,
            project_setting_attributes: { squash_option: squash_option }).execute
          return ServiceResponse.error(message: result[:message]) unless result[:status] == :success

          success_response
        end

        def execute_on_branch_rule
          ServiceResponse.error(message: NOT_SUPPORTED_ERROR_MESSAGE)
        end

        def success_response
          ServiceResponse.success(payload: branch_rule.squash_option)
        end

        def project
          branch_rule.project
        end

        def protected_branch
          branch_rule.protected_branch
        end

        def authorized?
          Ability.allowed?(current_user, :update_squash_option, branch_rule)
        end
      end
    end
  end
end

::Projects::BranchRules::SquashOptions::UpdateService.prepend_mod
