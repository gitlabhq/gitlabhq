# frozen_string_literal: true

module ProtectedBranchAccess
  extend ActiveSupport::Concern
  include ProtectedRefAccess

  included do
    belongs_to :protected_branch

    delegate :project, to: :protected_branch

    # We cannot delegate to :protected_branch here (even with allow_nil: true)
    # like above because it results in
    # 'undefined method `project_group_links' for nil:NilClass' errors.
    def protected_branch_group
      protected_branch.group
    end
  end
end

ProtectedBranchAccess.prepend_mod_with('ProtectedBranchAccess')
