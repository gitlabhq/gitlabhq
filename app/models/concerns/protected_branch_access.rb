module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    include ProtectedRefAccess

    belongs_to :protected_branch

    delegate :project, to: :protected_branch
  end
end
