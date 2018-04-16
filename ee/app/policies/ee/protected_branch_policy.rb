module EE
  module ProtectedBranchPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:can_unprotect) do
        @subject.can_unprotect?(@user)
      end

      condition(:unprotect_restrictions_enabled, scope: :subject) do
        @subject.project.feature_available?(:unprotection_restrictions)
      end

      rule { unprotect_restrictions_enabled & ~can_unprotect }.policy do
        prevent :create_protected_branch # Prevent a user creating a rule they wouldn't be able to update or destroy
        prevent :update_protected_branch
        prevent :destroy_protected_branch
      end
    end
  end
end
