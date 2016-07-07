class ProtectedBranch::PushAccessLevel < ActiveRecord::Base
  belongs_to :protected_branch

  enum access_level: [:masters, :developers]
end
