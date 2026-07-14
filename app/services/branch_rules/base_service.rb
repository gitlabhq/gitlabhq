# frozen_string_literal: true

# This base service is reusable for any sub-feature within branch rules.
#
#
# A base service should be created for the subfeature which inherits from this
# class. Name the base service following this format
# `BranchRules::{SubFeature}::BaseService`.
#
# module BranchRules
#   module ExternalStatusChecks
#     class BaseService < ::BranchRules::BaseService
#     end
#   end
# end
#
#
# Additionally you may want to pass in additional objects by overriding the
# initializer
#
# module BranchRules
#   module SquashOptions
#     class BaseService < ::BranchRules::BaseService
#       def initialize(branch_rule, user: nil, params: {}, squash_option: nil)
#         @squash_option = squash_option
#         super(branch_rule, user: user, params: params)
#       end
#       attr_reader :squash_option
#     end
#   end
# end
#
#
# If 1 or more of the branch rules types are not valid for the subfeature
# return an error from the base service for that
# `execute_on_{branch_rule_type}`.
#
# module BranchRules
#   module ExternalStatusChecks
#     class BaseService < ::BranchRules::BaseService
#       private
#
#       def execute_on_all_branches_rule
#         ServiceResponse.error(
#           message: 'All branch rules cannot configure external status checks',
#           payload: { errors: ['All branch rules not allowed'] },
#           reason: :unprocessable_entity
#         )
#       end
#     end
#   end
# end
#
#
# Name the services following this format
# `BranchRules::{SubFeature}::{Action}Service`.
#
# BranchRules::ExternalStatusChecks::CreateService
#
#
# Create an `execute_on_{branch_rule_type}` method for each branch rule type
# available for this subfeature. These can be used to define different logic
# for each branch rule type.
#
# module BranchRules
#   module ExternalStatusChecks
#     class CreateService < BaseService
#       private
#
#       def execute_on_branch_rule
#         params[:protected_branch_ids] = [branch_rule.id]
#         create_external_status_check
#       end
#
#       def execute_on_all_branches_rule
#         create_external_status_check
#       end
#
#       def create_external_status_check
#         ::ExternalStatusChecks::CreateService
#           .new(container: project, current_user: current_user, params: params)
#           .execute
#       end
#     end
#   end
# end
#
#
# Each service class must define `authorized?` to perform authorization
# during execution of the service. If a service intentionally does not
# require authorization, define `authorized?` to return `true` so the
# decision to skip authorization is explicit.
#
# module BranchRules
#   module ExternalStatusChecks
#     class CreateService < BaseService
#       private
#
#       def authorized?
#         can?(current_user, :create_external_status_check, branch_rule)
#       end
#
#       def execute_on_branch_rule
#         create_external_status_check(params.merge(protected_branch_ids: [branch_rule.id]))
#       end
#
#       def execute_on_all_branches_rule
#         create_external_status_check(params)
#       end
#     end
#   end
# end
#
module BranchRules
  class BaseService
    include Gitlab::Allowable

    MISSING_METHOD_ERROR = Class.new(StandardError)
    ACTION_NAME_MAP = {
      'CreateService' => 'create',
      'UpdateService' => 'update',
      'DestroyService' => 'delete'
    }.freeze

    attr_reader :branch_rule, :current_user, :params

    def initialize(branch_rule, user: nil, params: {})
      @branch_rule = branch_rule
      @current_user = user
      @params = params
    end

    def execute(skip_authorization: false)
      return access_denied unless skip_authorization || authorized?

      execute_on_branch_rule_type
    rescue Gitlab::Access::AccessDeniedError => error
      handle_access_denied_error(error)
    rescue ActiveRecord::RecordNotFound
      not_found_error
    end

    private

    # Hook for EE to translate specific access-denied errors (e.g. security
    # policy violations) into a more descriptive response. EE extensions can
    # override this method to surface user-facing messages for policy violations.
    def handle_access_denied_error(_error)
      access_denied
    end

    delegate :project, to: :branch_rule, allow_nil: true, private: true

    def all_branches_rule?
      branch_rule.is_a?(::Projects::AllBranchesRule)
    end

    def branch_rule?
      branch_rule.is_a?(::Projects::BranchRule)
    end

    def execute_on_branch_rule_type
      return execute_on_all_branches_rule if all_branches_rule?
      return execute_on_branch_rule if branch_rule?

      ServiceResponse.error(message: 'Unknown branch rule type.')
    end

    def execute_on_branch_rule
      missing_method_error('execute_on_branch_rule')
    end

    def execute_on_all_branches_rule
      missing_method_error('execute_on_all_branches_rule')
    end

    def authorized?
      missing_method_error('authorized?')
    end

    def access_denied
      ServiceResponse.error(
        message: "Failed to #{action} #{object_name}",
        payload: { errors: ['Not allowed'] },
        reason: :access_denied
      )
    end

    def not_found_error
      ServiceResponse.error(
        message: 'Record not found',
        payload: { errors: ['Not found'] },
        reason: :not_found
      )
    end

    def action
      ACTION_NAME_MAP.fetch(self.class.name.demodulize) do
        raise KeyError, "#{self.class.name} is not in ACTION_NAME_MAP. " \
          "Add an entry for #{self.class.name.demodulize}."
      end
    end

    # BranchRules::UpdateService -> `branch rule`
    # BranchRules::ExternalStatusChecks::CreateService -> `external status check`
    def object_name
      self.class.name.deconstantize.demodulize.singularize.underscore.tr('_', ' ')
    end

    def missing_method_error(method_name)
      raise MISSING_METHOD_ERROR, "Please define an `#{method_name}` method in #{self.class.name}"
    end
  end
end

BranchRules::BaseService.prepend_mod
