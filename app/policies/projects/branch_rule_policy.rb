# frozen_string_literal: true

module Projects
  class BranchRulePolicy < BasePolicy
    delegate(:project) { @subject.project }

    rule { ~can?(:_read_protected_branch_rule) }.prevent :read_branch_rule
  end
end

Projects::BranchRulePolicy.prepend_mod
