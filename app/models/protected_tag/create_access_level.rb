# frozen_string_literal: true

class ProtectedTag::CreateAccessLevel < ApplicationRecord
  include Importable
  include ProtectedTagAccess
  include ProtectedRefDeployKeyAccess
end
