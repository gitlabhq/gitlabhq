# frozen_string_literal: true

class ProtectedBranch::PushAccessLevel < ApplicationRecord
  include Importable
  include ProtectedBranchAccess
  include ProtectedRefDeployKeyAccess
  # default value for the access_level column
  GITLAB_DEFAULT_ACCESS_LEVEL = Gitlab::Access::MAINTAINER
end
