module EE
  module ProtectedBranch
    extend ActiveSupport::Concern

    included do
      protected_ref_access_levels :unprotect
    end

    def can_unprotect?(user)
      return true if unprotect_access_levels.empty?

      unprotect_access_levels.any? do |access_level|
        access_level.check_access(user)
      end
    end
  end
end
