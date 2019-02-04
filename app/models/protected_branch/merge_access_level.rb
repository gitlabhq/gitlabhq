# frozen_string_literal: true

class ProtectedBranch::MergeAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess
end
