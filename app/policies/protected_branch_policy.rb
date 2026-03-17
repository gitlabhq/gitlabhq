# frozen_string_literal: true

class ProtectedBranchPolicy < BasePolicy
  delegate { @subject.project || @subject.group }
end

ProtectedBranchPolicy.prepend_mod_with('ProtectedBranchPolicy')
