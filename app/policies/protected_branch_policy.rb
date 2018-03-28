class ProtectedBranchPolicy < BasePolicy
  delegate { @subject.project }

  rule { can?(:admin_project) }.policy do
    enable :create_protected_branch
    enable :update_protected_branch
    enable :destroy_protected_branch
  end
end
