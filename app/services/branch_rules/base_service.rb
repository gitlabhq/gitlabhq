# frozen_string_literal: true

module BranchRules
  class BaseService
    include Gitlab::Allowable

    attr_accessor :project, :branch_rule, :current_user

    def initialize(branch_rule, user = nil)
      @branch_rule = branch_rule
      @project = branch_rule.project
      @current_user = user
    end
  end
end

BranchRules::BaseService.prepend_mod
