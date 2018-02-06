module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    include ProtectedRefAccess

    belongs_to :protected_branch

    delegate :project, to: :protected_branch

    def check_access(user)
      return false if access_level == Gitlab::Access::NO_ACCESS

      super
    end
  end
end
