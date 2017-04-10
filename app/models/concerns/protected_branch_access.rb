module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    include ProtectedRefAccess
<<<<<<< HEAD
    include EE::ProtectedBranchAccess
=======
>>>>>>> 9-1-stable

    belongs_to :protected_branch

    delegate :project, to: :protected_branch
  end
end
