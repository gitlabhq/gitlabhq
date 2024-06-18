# frozen_string_literal: true

class ProtectedTag::CreateAccessLevel < ApplicationRecord
  include ProtectedTagAccess
  include ProtectedRefDeployKeyAccess
end
