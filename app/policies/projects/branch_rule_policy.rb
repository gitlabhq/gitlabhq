# frozen_string_literal: true

module Projects
  class BranchRulePolicy < ::ProtectedBranchPolicy
    rule { can?(:read_protected_branch) }.enable :read_branch_rule
    rule { can?(:create_protected_branch) }.enable :create_branch_rule
    rule { can?(:update_protected_branch) }.enable :update_branch_rule
    rule { can?(:destroy_protected_branch) }.enable :destroy_branch_rule
  end
end

Projects::BranchRulePolicy.prepend_mod
