# frozen_string_literal: true

module Projects
  class BranchRulePolicy < ::ProtectedBranchPolicy
    rule { can?(:admin_project) }.policy do
      enable :read_branch_rule
      enable :create_branch_rule
      enable :update_branch_rule
      enable :destroy_branch_rule
    end
  end
end

Projects::BranchRulePolicy.prepend_mod
