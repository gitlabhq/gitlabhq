# frozen_string_literal: true

class ExportedProtectedBranch < ProtectedBranch
  has_many :push_access_levels, -> { where(deploy_key_id: nil) }, class_name: "ProtectedBranch::PushAccessLevel", foreign_key: :protected_branch_id
end
