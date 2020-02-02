# frozen_string_literal: true

module API
  module Entities
    class ProtectedTag < Grape::Entity
      expose :name
      expose :create_access_levels, using: Entities::ProtectedRefAccess
    end
  end
end
