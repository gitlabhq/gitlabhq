# frozen_string_literal: true

module ProtectedBranchAccess
  extend ActiveSupport::Concern
  include ProtectedRefAccess

  included do
    belongs_to :protected_branch

    delegate :project, to: :protected_branch
  end
end
