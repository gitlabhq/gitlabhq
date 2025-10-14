# frozen_string_literal: true

module Projects
  class BranchRulePolicy < ::ProtectedBranchPolicy
    rule { can?(:admin_project) }.policy do
      enable :read_branch_rule
      enable :create_branch_rule
      enable :update_branch_rule
      enable :delete_branch_rule
    end

    rule { can?(:update_branch_rule) }.enable :update_squash_option
  end
end

Projects::BranchRulePolicy.prepend_mod
