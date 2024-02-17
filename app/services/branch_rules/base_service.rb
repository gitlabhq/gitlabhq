# frozen_string_literal: true

module BranchRules
  class BaseService
    include Gitlab::Allowable

    attr_reader :project, :branch_rule, :current_user, :params

    def initialize(branch_rule, user = nil, params = {})
      @branch_rule = branch_rule
      @project = branch_rule.project
      @current_user = user
      @params = params.slice(*permitted_params)
    end

    private

    def permitted_params
      []
    end
  end
end

BranchRules::BaseService.prepend_mod
