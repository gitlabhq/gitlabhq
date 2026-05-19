# frozen_string_literal: true

module Projects
  class BranchRulePolicy < BasePolicy
    delegate { @subject.project }

    # Custom branch rules (AllBranchesRule, AllProtectedBranchesRule) have no
    # protected_branch so this will evaluate to false for those.
    condition(:protected_branch_backed, scope: :subject) { @subject.protected_branch.present? }

    rule { protected_branch_backed & can?(:_read_protected_branch_rule) }.enable :read_branch_rule
  end
end

Projects::BranchRulePolicy.prepend_mod
