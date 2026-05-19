# frozen_string_literal: true

module Projects
  class AllBranchesRulePolicy < Projects::BranchRulePolicy
  end
end

Projects::AllBranchesRulePolicy.prepend_mod
