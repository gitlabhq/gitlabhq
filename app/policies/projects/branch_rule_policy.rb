# frozen_string_literal: true

module Projects
  class BranchRulePolicy < ::ProtectedBranchPolicy
  end
end

Projects::BranchRulePolicy.prepend_mod
