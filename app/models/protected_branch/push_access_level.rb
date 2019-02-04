# frozen_string_literal: true

class ProtectedBranch::PushAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess
end
