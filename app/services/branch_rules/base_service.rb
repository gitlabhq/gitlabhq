# frozen_string_literal: true

module BranchRules
  class BaseService
    include Gitlab::Allowable

    MISSING_METHOD_ERROR = Class.new(StandardError)

    attr_reader :branch_rule, :current_user, :params

    delegate :project, to: :branch_rule, allow_nil: true

    def initialize(branch_rule, user = nil, params = {})
      @branch_rule = branch_rule
      @current_user = user
      @params = ActionController::Parameters.new(**params).permit(*permitted_params).to_h
    end

    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?

      return execute_on_branch_rule if branch_rule.instance_of?(Projects::BranchRule)

      ServiceResponse.error(message: 'Unknown branch rule type.')
    end

    private

    def execute_on_branch_rule
      missing_method_error('execute_on_branch_rule')
    end

    def authorized?
      missing_method_error('authorized?')
    end

    def permitted_params
      []
    end

    def missing_method_error(method_name)
      raise MISSING_METHOD_ERROR, "Please define an `#{method_name}` method in #{self.class.name}"
    end
  end
end

BranchRules::BaseService.prepend_mod
