# frozen_string_literal: true

class ProtectedBranchPolicy < BasePolicy
  delegate { @subject.project }

  rule { can?(:admin_project) }.policy do
    enable :read_protected_branch
    enable :create_protected_branch
    enable :update_protected_branch
    enable :destroy_protected_branch
  end
end

ProtectedBranchPolicy.prepend_mod_with('ProtectedBranchPolicy')
