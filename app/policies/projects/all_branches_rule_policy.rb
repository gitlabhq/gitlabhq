# frozen_string_literal: true

module Projects
  class AllBranchesRulePolicy < BasePolicy
    delegate(:project) { @subject.project }

    rule { ~can?(:_read_custom_branch_rule) }.prevent :read_branch_rule
  end
end
