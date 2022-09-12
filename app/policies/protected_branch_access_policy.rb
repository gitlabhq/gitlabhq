# frozen_string_literal: true

class ProtectedBranchAccessPolicy < BasePolicy
  delegate { @subject.protected_branch }
end
