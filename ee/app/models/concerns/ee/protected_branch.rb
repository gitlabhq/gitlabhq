module EE
  module ProtectedBranch
    extend ActiveSupport::Concern

    included do
      protected_ref_access_levels :unprotect
    end
  end
end
